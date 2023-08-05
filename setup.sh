#!/bin/bash
set -e
set -o pipefail

# Last tested with archlinux-2023.08.01-x86_64.iso
#
# Make sure you are okay with $drive being reformatted
readonly drive="${ARCH_SETUP_DRIVE:-/dev/sd<X>}"
readonly encrypt=false
readonly swap="" # set to a value if you want swap
readonly hostname="arch"
readonly lang="en_US.UTF-8"
readonly timezone="UTC"
readonly btrfs_options=noatime,compress-force=zstd:1
readonly home_btrfs_options=nodev,nosuid,$btrfs_options

readonly dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# or maybe efivar --list
if ! [ -d "/sys/firmware/efi" ]; then
  echo "Installation only supports EFI"
  exit 1
fi

root_index=2
partition_prefix=""
if echo "$drive" | grep -q -e "^/dev/nvme"; then
  partition_prefix="p"
fi

sgdisk --clear -g "$drive"
sgdisk -n 1:0:+512M -c 1:boot -t 1:ef00 "$drive"
if [ -n "$swap" ]; then
  sgdisk -n "2:0:+$swap" -c 2:swap -t 2:8200 "$drive"
  ((root_index++))
fi
sgdisk -n $root_index:0:0 -c $root_index:root -t $root_index:8304 "$drive"

readonly boot="${drive}${partition_prefix}1"
readonly root="${drive}${partition_prefix}${root_index}"

mkfs.fat -F32 "$boot"

if [ -n "$swap" ]; then
  mkswap "${drive}${partition_prefix}2"

  if [ "$encrypt" = true ] ; then
    readonly swap_disk_id=$(find -L /dev/disk -samefile "${drive}${partition_prefix}2" | grep '^/dev/disk/by-id/' | sort | head -n 1)
    if [ -z "$swap_id" ]; then
      echo "Could not find swap disk id for partition ${drive}${partition_prefix}2"
      exit 1
    fi

    echo "swap  $swap_disk_id  /dev/urandom  swap,cipher=aes-xts-plain64,size=512" >> /etc/crypttab
    echo "/dev/mapper/swap  none  swap  defaults  0  0" >> /etc/fstab
  fi
fi

if [ "$encrypt" = true ] ; then
  cryptsetup -v \
    --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random \
    --perf-no_read_workqueue --perf-no_write_workqueue \
    --verify-passphrase luksFormat "$root"
  cryptsetup open "$root" root

  install_drive=/dev/mapper/root
else
  install_drive="$root"
fi

mkfs.btrfs -f -L arch "$install_drive"
mount "$install_drive" /mnt
cd /mnt
btrfs subvolume create __active
btrfs subvolume create __active/root
btrfs subvolume create __active/home
btrfs subvolume create __snapshots

cd /
umount /mnt
mount -o $btrfs_options,subvol=__active/root "$install_drive" /mnt
mkdir /mnt/home
mount -o $home_btrfs_options,subvol=__active/home "$install_drive" /mnt/home
mkdir /mnt/efi
mount -o nodev,nosuid,noexec "$boot" /mnt/efi

readonly cpu_vendor=$(lscpu | grep 'Vendor ID')
ucode=""
if [[ $cpu_vendor == *"AuthenticAMD"* ]]; then
  ucode="amd-ucode"
elif [[ $cpu_vendor == *"GenuineIntel"* ]]; then
  ucode="intel-ucode"
fi

pacstrap /mnt base linux linux-firmware btrfs-progs cryptsetup efibootmgr \
  pacman-contrib openssh sudo systemd-resolvconf vim wpa_supplicant $ucode

echo "$hostname" > /mnt/etc/hostname
sed -i "/^127.0.0.1/ s/ localhost/ localhost $hostname/" /mnt/etc/hosts
arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
sed -i "/$lang/ s/# *//" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$lang" > /mnt/etc/locale.conf

echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf

readonly root_uuid=$(arch-chroot /mnt blkid -s UUID -o value "$root")
if [ "$encrypt" = true ] ; then

cat << EOF > "/mnt/etc/crypttab.initramfs"
root  UUID=$root_uuid  -  password-echo=no,x-systemd.device-timeout=0,timeout=0
EOF

  initrd_root="/dev/mapper/root"
  home_mount_path="/dev/mapper/root"
else
  initrd_root="UUID=$root_uuid"
  home_mount_path="/dev/disk/by-uuid/$root_uuid"
fi

readonly esp="/efi"
arch-chroot /mnt bootctl --path="$esp" install

cat << EOF > "/mnt/$esp/loader/loader.conf"
default  arch-linux.efi
timeout  3
editor   no
console-mode max
EOF
cat << EOF > "/mnt/etc/kernel/cmdline"
root=$initrd_root rootflags=$btrfs_options,subvol=__active/root cgroup_enable=memory swapaccount=1
EOF
cat << EOF > "/mnt/etc/kernel/cmdline_fallback"
root=$initrd_root rootflags=subvol=__active/root
EOF

if [ "$encrypt" = true ] ; then
  sed -i "s/^HOOKS=.*/HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/" /mnt/etc/mkinitcpio.conf
else
  sed -i "s/^HOOKS=.*/HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block filesystems fsck)/" /mnt/etc/mkinitcpio.conf
fi
cat << EOF > "/mnt/etc/mkinitcpio.d/linux.preset"
#ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
ALL_microcode=(/boot/*-ucode.img)

PRESETS=('default' 'fallback')

default_uki="$esp/EFI/Linux/arch-linux.efi"

fallback_uki="$esp/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect --cmdline /etc/kernel/cmdline_fallback"
EOF
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
arch-chroot /mnt mkinitcpio -p linux

# mount files generated from fstab live in /run/systemd/generator/
cat << EOF > "/mnt/etc/systemd/system/home.mount"
[Unit]
Before=local-fs.target
After=-.mount

[Mount]
What=$home_mount_path
Where=/home
Type=btrfs
Options=$home_btrfs_options,subvol=/__active/home
EOF

find "$dir/config/" -type f -print0 | xargs -0 chmod 644
find "$dir/config/initcpio/post/" -type f -print0 | xargs -0 chmod 755

# initcpio hooks
arch-chroot /mnt mkdir -p /etc/initcpio/post/
cp "$dir/config/initcpio/post/"* /mnt/etc/initcpio/post/

# pacman hooks
arch-chroot /mnt mkdir -p /etc/pacman.d/hooks/
cp "$dir/config/pacman/hooks/"* /mnt/etc/pacman.d/hooks/

# sudo
cp "$dir/config/sudoers.d/"* /mnt/etc/sudoers.d/

# journal
arch-chroot /mnt mkdir -p /etc/systemd/journald.conf.d/
cp "$dir/config/journal.conf.d/"* /mnt/etc/systemd/journald.conf.d/

# network
cp "$dir/config/network/"* /mnt/etc/systemd/network/
arch-chroot /mnt systemctl enable systemd-networkd.service
arch-chroot /mnt systemctl disable systemd-networkd-wait-online.service
arch-chroot /mnt systemctl mask systemd-networkd-wait-online.service

# time
cp "$dir/config/timesyncd.conf" /mnt/etc/systemd/
arch-chroot /mnt systemctl enable systemd-timesyncd.service

# dns
arch-chroot /mnt mkdir -p /etc/systemd/resolved.conf.d/
cp "$dir/config/resolved.conf.d/"* /mnt/etc/systemd/resolved.conf.d/
arch-chroot /mnt systemctl enable systemd-resolved.service
rm /mnt/etc/resolv.conf # avoid device or resource busy when running from inside chroot
arch-chroot /mnt ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# sysctl
arch-chroot /mnt mkdir -p /etc/sysctl.d/
cp "$dir/config/sysctl.d/"* /mnt/etc/sysctl.d/

# drive maintenance
arch-chroot /mnt systemctl enable fstrim.timer
#arch-chroot /mnt systemctl enable btrfs-scrub@-.timer
# the above does not work during install so just create the system link manually
arch-chroot /mnt ln -s /usr/lib/systemd/system/btrfs-scrub@.timer "/etc/systemd/system/timers.target.wants/btrfs-scrub@-.timer"

# https://wiki.archlinux.org/index.php/Secure_Boot#PreLoader
arch-chroot /mnt curl -s -o $esp/EFI/systemd/PreLoader.efi https://blog.hansenpartnership.com/wp-uploads/2013/PreLoader.efi
echo "c73583439ad989f5eb3a68753df56a06dc2f04b637415e3c515c74654651e0991a1d5f0ab84da4cd1d681d29a35271ff584a5b988b28ce1b810f94c0d0a57aff  /mnt$esp/EFI/systemd/PreLoader.efi" | sha512sum --check -
arch-chroot /mnt curl -s -o $esp/EFI/systemd/HashTool.efi https://blog.hansenpartnership.com/wp-uploads/2013/HashTool.efi
echo "a51ce176c93417e53ec6d78c16afa5e8b9545e623d98d4fc55fc3762f33cd942ea1dce1211b2ed80703df08fe4fed84aff1fa86063c27b08413b3882019c4afd  /mnt$esp/EFI/systemd/HashTool.efi" | sha512sum --check -
arch-chroot /mnt cp $esp/EFI/systemd/systemd-bootx64.efi $esp/EFI/systemd/loader.efi

if bootctl status | grep 'Secure Boot' | cut -d ":" -f 2 | grep "enabled" ; then
  # https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface/Secure_Boot#Set_up_PreLoader
  efibootmgr --verbose --disk "$drive" --part 1 --create --label 'PreLoader' --loader /EFI/systemd/PreLoader.efi
fi

# user
arch-chroot /mnt useradd --create-home -s /bin/bash \
  -G wheel,uucp,log,video,audio,optical,storage,power \
  -p "$(echo user | openssl passwd -1 -stdin)" user

cp -a "$dir/ansible" /mnt/home/user/.archlinux-setup
arch-chroot /mnt chown -R user:user /home/user/.archlinux-setup

echo ""
echo ""
echo "Setup complete, reboot, log in as user (password is user), and run ./.archlinux-setup/run.sh"
echo ""
