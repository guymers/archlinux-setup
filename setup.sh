#!/bin/bash
set -e
set -o pipefail

# Last tested with archlinux-2025.10.01-x86_64.iso
#
# Make sure you are okay with $drive being reformatted
readonly drive_main="${ARCH_SETUP_DRIVE:-/dev/nvme<X>n1}"
readonly swap_amount="" # set to a value if you want swap
readonly hostname="arch-temp"
readonly lang="en_US.UTF-8"
readonly timezone="UTC"
readonly btrfs_options=noatime,compress-force=zstd:1
readonly home_btrfs_options=nodev,nosuid,$btrfs_options
readonly kernel="linux" # linux-hardened, linux-zen

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly dir

# or maybe efivar --list
if ! [ -d "/sys/firmware/efi" ]; then
  echo "Installation only supports EFI"
  exit 1
fi

readonly esp="/efi"

extra_packages=()

boot_drive=
root_drives=()
swap_labels=()

function partition() {
  local drive="$1"
  local index="$2"

  local root_index=2
  local partition_prefix=""
  if echo "$drive" | grep -q -e "^/dev/nvme"; then
    partition_prefix="p"
  fi

  sgdisk --clear -g "$drive"
  sgdisk -n 1:0:+512M -c 1:boot -t 1:ef00 "$drive"
  if [ -n "$swap_amount" ]; then
    sgdisk -n "2:0:+$swap_amount" -c 2:swap -t 2:8200 "$drive"
    ((root_index++))
  fi
  sgdisk -n $root_index:0:0 -c $root_index:root -t $root_index:8304 "$drive"

  boot_drive="${drive}${partition_prefix}1"
  local root_drive="${drive}${partition_prefix}${root_index}"

  if [ -n "$swap_amount" ]; then
    local swap="${drive}${partition_prefix}2"
    # https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption#UUID_and_LABEL
    mkfs.ext2 -L "cryptswap${index}" "${swap}" 1M
    swap_labels+=("cryptswap${index}")
  fi

  cryptsetup -v \
    --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random \
    --perf-no_read_workqueue --perf-no_write_workqueue \
    --verify-passphrase luksFormat "$root_drive"
  cryptsetup open "$root_drive" "root${index}"

  mkfs.fat -F32 -n esp "$boot_drive"
  root_drives+=("$root_drive")
}

partition "$drive_main" ""
mkfs.btrfs -f -L archroot /dev/mapper/root

root_fs=/dev/disk/by-label/archroot
# installing on an sdcard and the label didn't exist, so fallback to the mapper
if [[ ! -f "$root_fs" ]]; then
  root_fs=/dev/mapper/root
fi
mount "$root_fs" /mnt
cd /mnt
btrfs subvolume create _
btrfs subvolume create _/@
btrfs subvolume create _/@var
btrfs subvolume create _/@home

cd /
umount /mnt
mount -o $btrfs_options,subvol=_/@ "$root_fs" /mnt
mkdir /mnt/var
mount -o $btrfs_options,subvol=_/@var "$root_fs" /mnt/var
mkdir /mnt/home
mount -o $home_btrfs_options,subvol=_/@home "$root_fs" /mnt/home
mkdir "/mnt/$esp"
mount -o nodev,nosuid,noexec "$boot_drive" "/mnt/$esp"
mkdir -p "/mnt/$esp/EFI/Linux"

cpu_vendor=$(lscpu | grep 'Vendor ID')
readonly cpu_vendor
if [[ $cpu_vendor == *"AuthenticAMD"* ]]; then
  extra_packages+=(amd-ucode)
elif [[ $cpu_vendor == *"GenuineIntel"* ]]; then
  extra_packages+=(intel-ucode)
fi

if printf '%s\n' /sys/class/net/*/wireless | grep -v '/sys/class/net/\*/wireless'; then
  extra_packages+=(wpa_supplicant)
fi

if [[ -n "$ARCH_SETUP_PACMAN_MIRROR" ]]; then
  echo "Server = $ARCH_SETUP_PACMAN_MIRROR" > /etc/pacman.d/mirrorlist
fi

sed -i 's|^#ParallelDownloads.*|ParallelDownloads = 3|' /etc/pacman.conf
pacstrap /mnt base "$kernel" linux-firmware btrfs-progs cryptsetup efibootmgr systemd-ukify \
  bash-completion dosfstools pacman-contrib openssh sudo vim \
  "${extra_packages[@]}"

echo "$hostname" > /mnt/etc/hostname
arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
sed -i "/$lang/ s/# *//" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$lang" > /mnt/etc/locale.conf

echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf

for i in "${!root_drives[@]}"; do
  root_uuid=$(arch-chroot /mnt blkid -s UUID -o value "${root_drives[$i]}")
  n="root$((i + 1))"
  if [[ "${#root_drives[@]}" -eq 1 ]]; then n="root"; fi
  echo "$n  UUID=$root_uuid  -  password-echo=no,x-systemd.device-timeout=60,timeout=0" >> /mnt/etc/crypttab.initramfs
done

for i in "${!swap_labels[@]}"; do
  echo "swap$i  LABEL=${swap_labels[$i]}  /dev/urandom  swap,cipher=aes-xts-plain64,size=512,offset=2048" >> /mnt/etc/crypttab
  echo "/dev/mapper/swap$i  none  swap  defaults  0  0" >> /mnt/etc/fstab
done

readonly cmdline_options="rw rd.shell=0 rd.emergency=reboot"
cat << EOF > "/mnt/etc/kernel/cmdline"
root=$root_fs rootflags=$btrfs_options,subvol=_/@ $cmdline_options
EOF

cp "$dir/config/initcpio/install/"* /mnt/etc/initcpio/install/

sed -i "s/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard block sd-encrypt sd-volatile filesystems fsck)/" /mnt/etc/mkinitcpio.conf
cat << EOF > "/mnt/etc/mkinitcpio.d/$kernel.preset"
ALL_kver="/boot/vmlinuz-$kernel"

PRESETS=('default')

default_uki="$esp/EFI/Linux/arch-$kernel.efi"
EOF
arch-chroot /mnt mkinitcpio -p "$kernel"

# systemd-gpt-auto-generator generates efi.mount
boot_drive_uuid=$(arch-chroot /mnt blkid -s PARTUUID -o value "$boot_drive")
boot_drive_escaped=$(arch-chroot /mnt systemd-escape "dev/disk/by-partuuid/$boot_drive_uuid")
mkdir -p /mnt/etc/systemd/system/efi.mount.d/
cat << EOF > "/mnt/etc/systemd/system/efi.mount.d/fsck.conf"
[Unit]
Wants=systemd-fsck@${boot_drive_escaped}.service
EOF

cat << EOF > "/mnt/etc/systemd/system/var.mount"
[Unit]
Before=local-fs.target
After=-.mount

[Mount]
What=$root_fs
Where=/var
Type=btrfs
Options=rw,$btrfs_options,subvol=_/@var
EOF

cat << EOF > "/mnt/etc/systemd/system/home.mount"
[Unit]
Before=local-fs.target
After=-.mount

[Mount]
What=$root_fs
Where=/home
Type=btrfs
Options=rw,$home_btrfs_options,subvol=_/@home
EOF

find "$dir/config/" -type f -print0 | xargs -0 chmod 644

# pacman hooks
arch-chroot /mnt mkdir -p /etc/pacman.d/hooks/
cp "$dir/config/pacman/hooks/"* /mnt/etc/pacman.d/hooks/

# pacman
# allow readonly /etc
arch-chroot /mnt sed -i 's|^#GPGDir.*=.*/etc/pacman.d/gnupg/$|GPGDir = /var/lib/pacman/gnupg/|' /etc/pacman.conf
arch-chroot /mnt grep -q 'GPGDir = /var/lib/pacman/gnupg/' /etc/pacman.conf
arch-chroot /mnt mv /etc/pacman.d/gnupg /var/lib/pacman/
# https://gitlab.archlinux.org/archlinux/packaging/packages/pacman/-/blob/6.1.0-3/PKGBUILD
for unit in dirmngr gpg-agent gpg-agent-{browser,extra,ssh} keyboxd; do
  arch-chroot /mnt ln -s "/usr/lib/systemd/system/${unit}@.socket" "/usr/lib/systemd/system/sockets.target.wants/${unit}@var-lib-pacman-gnupg.socket"
  arch-chroot /mnt rm "/usr/lib/systemd/system/sockets.target.wants/${unit}@etc-pacman.d-gnupg.socket"
done

arch-chroot /mnt sed -i 's|^#Color$|Color|' /etc/pacman.conf
arch-chroot /mnt sed -i 's|^#VerbosePkgLists$|VerbosePkgLists|' /etc/pacman.conf
arch-chroot /mnt sed -i 's|^#ParallelDownloads.*|ParallelDownloads = 3|' /etc/pacman.conf

# makepkg
arch-chroot /mnt sed -i 's|-march=x86-64 -mtune=generic|-march=native|' /etc/makepkg.conf
cp "$dir/config/makepkg.conf.d/"* /mnt/etc/makepkg.conf.d/

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
arch-chroot /mnt mkdir -p /etc/systemd/timesyncd.conf.d/
cp "$dir/config/timesyncd.conf.d/"* /mnt/etc/systemd/timesyncd.conf.d/
arch-chroot /mnt systemctl enable systemd-timesyncd.service

# dns
arch-chroot /mnt mkdir -p /etc/systemd/resolved.conf.d/
cp "$dir/config/resolved.conf.d/"* /mnt/etc/systemd/resolved.conf.d/
arch-chroot /mnt systemctl enable systemd-resolved.service
rm /mnt/etc/resolv.conf # avoid device or resource busy when running from inside chroot
arch-chroot /mnt ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# core dumps
arch-chroot /mnt mkdir -p /etc/systemd/coredump.conf.d/
cp "$dir/config/coredump.conf.d/"* /mnt/etc/systemd/coredump.conf.d/

# sysctl
arch-chroot /mnt mkdir -p /etc/sysctl.d/
cp "$dir/config/sysctl.d/"* /mnt/etc/sysctl.d/

# drive maintenance
arch-chroot /mnt systemctl enable fstrim.timer
#arch-chroot /mnt systemctl enable btrfs-scrub@-.timer
# the above does not work during install so just create the system link manually
arch-chroot /mnt ln -s /usr/lib/systemd/system/btrfs-scrub@.timer "/etc/systemd/system/timers.target.wants/btrfs-scrub@-.timer"

efibootmgr -t 3 || echo "could not change boot timeout"

efibootmgr --create --disk "$drive_main" --part 1 --label "Arch Linux" --loader "EFI\Linux\arch-$kernel.efi"

arch-chroot /mnt bootctl random-seed

# if secure boot is already enabled probably dual booting so install the pre-loader
if bootctl status | grep 'Secure Boot' | cut -d ":" -f 2 | grep "enabled" ; then
  arch-chroot /mnt mkdir -p "$esp/EFI/systemd"

  # https://wiki.archlinux.org/index.php/Secure_Boot#PreLoader
  arch-chroot /mnt curl -s -o "$esp/EFI/systemd/PreLoader.efi" https://blog.hansenpartnership.com/wp-uploads/2013/PreLoader.efi
  echo "c73583439ad989f5eb3a68753df56a06dc2f04b637415e3c515c74654651e0991a1d5f0ab84da4cd1d681d29a35271ff584a5b988b28ce1b810f94c0d0a57aff  /mnt$esp/EFI/systemd/PreLoader.efi" | sha512sum --check -
  arch-chroot /mnt curl -s -o "$esp/EFI/systemd/HashTool.efi" https://blog.hansenpartnership.com/wp-uploads/2013/HashTool.efi
  echo "a51ce176c93417e53ec6d78c16afa5e8b9545e623d98d4fc55fc3762f33cd942ea1dce1211b2ed80703df08fe4fed84aff1fa86063c27b08413b3882019c4afd  /mnt$esp/EFI/systemd/HashTool.efi" | sha512sum --check -

  # https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface/Secure_Boot#Set_up_PreLoader
  efibootmgr --create --disk "$drive_main" --part 1 --label 'PreLoader' --loader /EFI/systemd/PreLoader.efi
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
