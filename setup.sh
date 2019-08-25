#!/bin/bash
set -e
set -o pipefail

# Last tested with archlinux-2019.08.01-x86_64.iso
#
# Make sure you are okay with $drive being reformatted
readonly drive=/dev/sda
readonly encrypt=false
readonly swap="" # set to a value if you want swap
readonly hostname="arch"
readonly lang="en_AU.UTF-8"
readonly timezone="Australia/Queensland"
readonly btrfs_options=noatime,space_cache,compress=lzo

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
sgdisk -n $root_index:0:0 -c $root_index:root -t $root_index:8300 "$drive"

readonly boot="${drive}${partition_prefix}1"
readonly root="${drive}${partition_prefix}${root_index}"

mkfs.fat -F32 "$boot"

if [ -n "$swap" ]; then
  mkswap "${drive}${partition_prefix}2"
fi

if [ "$encrypt" = true ] ; then
  cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random --verify-passphrase luksFormat "$root"
  cryptsetup open "$root" cryptroot

  install_drive=/dev/mapper/cryptroot
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
mount -o nodev,nosuid,$btrfs_options,subvol=__active/home "$install_drive" /mnt/home
mkdir /mnt/boot
mount -o nodev,nosuid,noexec "$boot" /mnt/boot

echo "Server = http://mirror.internode.on.net/pub/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
echo "#Server = http://ftp.iinet.net.au/pub/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
pacstrap /mnt base mtools gptfdisk efibootmgr openssh vim ansible

genfstab -U -p /mnt >> /mnt/etc/fstab

echo "$hostname" > /mnt/etc/hostname
sed -i "/^127.0.0.1/ s/ localhost/ localhost $hostname/" /mnt/etc/hosts
arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
sed -i "/$lang/ s/# *//" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$lang" > /mnt/etc/locale.conf

echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf

echo "vm.oom_kill_allocating_task=1" > /mnt/etc/sysctl.d/vm.conf
echo "vm.swappiness=5" >> /mnt/etc/sysctl.d/vm.conf

# btrfs does not need to fsck on boot
sed -i "/^HOOKS/ s/ fsck//" /mnt/etc/mkinitcpio.conf
if [ "$encrypt" = true ] ; then
  sed -i "/^HOOKS/ s/filesystems/encrypt filesystems/" /mnt/etc/mkinitcpio.conf
fi
arch-chroot /mnt mkinitcpio -p linux

readonly root_uuid=$(arch-chroot /mnt blkid -s UUID -o value "$root")
if [ "$encrypt" = true ] ; then
  initrd_root="/dev/mapper/cryptroot cryptdevice=UUID=$root_uuid:cryptroot"
else
  initrd_root="UUID=$root_uuid"
fi

# https://wiki.archlinux.org/index.php/Systemd-boot
readonly esp="/boot"
arch-chroot /mnt bootctl --path="$esp" install
cat << EOF > "/mnt/usr/share/libalpm/hooks/systemd-boot.hook"
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot...
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF
cat << EOF > "/mnt/$esp/loader/loader.conf"
default  arch
timeout  3
console-mode max
editor   no
EOF
cat << EOF > "/mnt/$esp/loader/entries/arch.conf"
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=$initrd_root rootflags=subvol=__active/root cgroup_enable=memory swapaccount=1
EOF
cat << EOF > "/mnt/$esp/loader/entries/arch-fallback.conf"
title   Arch Linux Fallback
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=$initrd_root rootflags=subvol=__active/root
EOF

mkdir /mnt/archlinux-setup
mount --bind "$dir" /mnt/archlinux-setup
arch-chroot /mnt ansible-playbook --inventory-file=/archlinux-setup/ansible/inventory --limit=local /archlinux-setup/ansible/setup.yml
umount /mnt/archlinux-setup
rm -r /mnt/archlinux-setup

pacman -Sy --noconfirm rsync
mkdir /mnt/home/user/.archlinux-setup
# copy setup folder excluding hidden files
rsync -av "$dir/ansible/" /mnt/home/user/.archlinux-setup/
arch-chroot /mnt chown -R user:user /home/user/.archlinux-setup

arch-chroot /mnt systemctl enable dhcpcd
arch-chroot /mnt bash -c "echo yes" | pacman -Scc

arch-chroot /mnt systemctl enable fstrim.timer
#arch-chroot /mnt systemctl enable btrfs-scrub@-.timer
# the above does not work during install so just create the system link manually
btrfs_scrub_device=${root//[\/]/-} # replace / with -
btrfs_scrub_device=${btrfs_scrub_device#"-"} # remove leading -
arch-chroot /mnt ln -s /usr/lib/systemd/system/btrfs-scrub@.timer "/etc/systemd/system/multi-user.target.wants/btrfs-scrub@$btrfs_scrub_device.timer"

echo ""
echo ""
echo "Setup complete, reboot, log in as user (password is user), and run ./.archlinux-setup/run.sh"
echo ""
echo "For secure boot support run:"
echo "  efibootmgr --verbose --disk $driver --part 1 --create --label 'PreLoader' --loader /EFI/systemd/PreLoader.efi"
