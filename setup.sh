#!/bin/bash
set -e
set -o pipefail

# Last tested with archlinux-2018.12.01-x86_64.iso
#
# Make sure you are okay with $drive being reformatted
readonly drive=/dev/sda
readonly encrypt=false
readonly swap=""
readonly hostname="arch"
readonly lang="en_AU.UTF-8"
readonly timezone="Australia/Queensland"
readonly btrfs_options=noatime,space_cache,compress=lzo

readonly dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -d "/sys/firmware/efi" ] && efi=true || efi=false;
root_index=2

partition_prefix=""
if echo "$drive" | grep -q -e "^/dev/nvme"; then
  partition_prefix="p"
fi

sgdisk --clear -g "$drive"
sgdisk -n 1:0:+512M -c 1:boot -t 1:ef00 "$drive"
if [ -n "$swap" ]; then
  sgdisk -n 2:0:+$swap -c 2:swap -t 2:8200 "$drive"
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
btrfs subvolume create __active/rootvol
btrfs subvolume create __active/home
btrfs subvolume create __active/var
btrfs subvolume create __snapshots

cd /
umount /mnt
mount -o $btrfs_options,subvol=__active/rootvol "$install_drive" /mnt
mkdir /mnt/home
mount -o nodev,nosuid,$btrfs_options,subvol=__active/home "$install_drive" /mnt/home
mkdir /mnt/var
mount -o nodev,nosuid,$btrfs_options,subvol=__active/var "$install_drive" /mnt/var
mkdir /mnt/boot
mount -o nodev,nosuid,noexec "$boot" /mnt/boot

echo "Server = http://mirror.internode.on.net/pub/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
echo "#Server = http://ftp.iinet.net.au/pub/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
echo "#Server = http://ftp.swin.edu.au/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
pacstrap /mnt base mtools gptfdisk syslinux openssh vim ansible

genfstab -U -p /mnt >> /mnt/etc/fstab

echo "$hostname" > /mnt/etc/hostname
sed -i "/^127.0.0.1/ s/ localhost/ localhost $hostname/" /mnt/etc/hosts
arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
sed -i "/$lang/ s/# *//" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$lang" > /mnt/etc/locale.conf

echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf

echo "vm.swappiness=1" > /mnt/etc/sysctl.d/swappiness.conf

# btrfs does not need to fsck on boot
sed -i "/^HOOKS/ s/ fsck//" /mnt/etc/mkinitcpio.conf
if [ "$encrypt" = true ] ; then
  sed -i "/^HOOKS/ s/filesystems/encrypt filesystems/" /mnt/etc/mkinitcpio.conf
fi
arch-chroot /mnt mkinitcpio -p linux

readonly root_uuid=$(arch-chroot /mnt blkid -s UUID -o value "$root")

if [ "$efi" = true ] ; then
  # https://wiki.archlinux.org/index.php/syslinux#UEFI_Systems
  readonly esp="/boot"
  syslinux_config="$esp/EFI/syslinux/syslinux.cfg"
  boot_relative_path="../.."
  arch-chroot /mnt pacman -S --noconfirm efibootmgr
  arch-chroot /mnt mkdir -p "$esp/EFI/syslinux"
  arch-chroot /mnt cp -r /usr/lib/syslinux/efi64/* "$esp/EFI/syslinux/"
  arch-chroot /mnt efibootmgr -c -d "$drive" -p 1 -l /EFI/syslinux/syslinux.efi -L "Archlinux"
else
  syslinux_config="/boot/syslinux/syslinux.cfg"
  boot_relative_path=".."
  syslinux-install_update -i -a -m -c /mnt
fi
arch-chroot /mnt cp /usr/share/hwdata/pci.ids "$(dirname "$syslinux_config")/pci.ids"
if [ "$encrypt" = true ] ; then
  syslinux_root="/dev/mapper/cryptroot cryptdevice=UUID=$root_uuid:cryptroot"
else
  syslinux_root="UUID=$root_uuid"
fi
cat << EOF > "/mnt/$syslinux_config"
DEFAULT arch
TIMEOUT 100
# hold either Shift or Alt, or setting either Caps Lock or Scroll Lock, during boot to see prompt
PROMPT 0

LABEL arch
  MENU LABEL Arch Linux
  LINUX $boot_relative_path/vmlinuz-linux
  APPEND root=$syslinux_root rootflags=subvol=__active/rootvol cgroup_enable=memory swapaccount=1
  INITRD $boot_relative_path/initramfs-linux.img

LABEL archfallback
  MENU LABEL Arch Linux Fallback
  LINUX $boot_relative_path/vmlinuz-linux
  APPEND root=$syslinux_root rootflags=subvol=__active/rootvol
  INITRD $boot_relative_path/initramfs-linux-fallback.img

LABEL hdt
  MENU LABEL HDT (Hardware Detection Tool)
  COM32 hdt.c32

LABEL reboot
  MENU LABEL Reboot
  COM32 reboot.c32

LABEL poweroff
  MENU LABEL Poweroff
  COM32 poweroff.c32
EOF

mkdir /mnt/archlinux-setup
mount --bind "$dir" /mnt/archlinux-setup
arch-chroot /mnt ansible-playbook --inventory-file=/archlinux-setup/ansible/inventory --limit=local /archlinux-setup/ansible/user.yml
arch-chroot /mnt systemctl enable fstrim.timer
if [ "$encrypt" = true ] ; then
  arch-chroot /mnt systemctl enable btrfs-scrub@dev-mapper-cryptroot.timer
fi
umount /mnt/archlinux-setup
rm -r /mnt/archlinux-setup

pacman -Sy --noconfirm rsync
mkdir /mnt/home/user/.archlinux-setup
# copy setup folder excluding hidden files
rsync -av "$dir/ansible/" /mnt/home/user/.archlinux-setup/
arch-chroot /mnt chown -R user:user /home/user/.archlinux-setup

arch-chroot /mnt systemctl enable dhcpcd
arch-chroot /mnt bash -c "echo yes" | pacman -Scc

echo ""
echo ""
echo "Setup complete, reboot, log in as user (password is user), and run ./.archlinux-setup/run.sh"
