#!/bin/sh
# Last tested with archlinux-2016.03.01-dual.iso
#
# Make sure you are okay with $drive being reformatted
drive=/dev/sda
encrypt=false
swap="2G"
hostname="arch"
lang="en_AU.UTF-8"
timezone="Australia/Queensland"

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root_index=2

sgdisk --clear -g $drive
sgdisk -n 1:0:+512M -c 1:boot -t 1:ef00 $drive
if [ -n "$swap" ]; then
  sgdisk -n 2:0:+$swap -c 2:swap -t 2:8200 $drive
  ((root_index++))
fi
sgdisk -n $root_index:0:0 -c $root_index:root -t $root_index:8300 $drive

boot="${drive}1"
root="${drive}${root_index}"
btrfs_options=noatime,space_cache,compress=lzo

mkfs.fat -F32 $boot

if [ -n "$swap" ]; then
  mkswap "${drive}2"
fi

if [ "$encrypt" = true ] ; then
  cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat $root
  cryptsetup open $root cryptroot
fi

if [ "$encrypt" = true ] ; then
  install_drive=/dev/mapper/cryptroot
else
  install_drive=$root
fi

mkfs.btrfs -f -L arch $install_drive
mount $install_drive /mnt
cd /mnt
btrfs subvolume create __active
btrfs subvolume create __active/rootvol
btrfs subvolume create __active/home
btrfs subvolume create __active/var
btrfs subvolume create __snapshots

cd /
umount /mnt
mount -o $btrfs_options,subvol=__active/rootvol $install_drive /mnt
mkdir /mnt/home
mount -o $btrfs_options,subvol=__active/home $install_drive /mnt/home
mkdir /mnt/var
mount -o $btrfs_options,subvol=__active/var $install_drive /mnt/var
mkdir /mnt/boot
mount $boot /mnt/boot

echo "Server = http://mirror.internode.on.net/pub/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
pacstrap /mnt base mtools gptfdisk syslinux openssh vim ansible

genfstab -U -p /mnt >> /mnt/etc/fstab

echo $hostname > /mnt/etc/hostname
sed -i "/^127.0.0.1/ s/ localhost/ localhost $hostname/" /mnt/etc/hosts
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
sed -i "/$lang/ s/# *//" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$lang" > /mnt/etc/locale.conf

echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf

if [ "$encrypt" = true ] ; then
  sed -i "/^HOOKS/ s/filesystems/encrypt filesystems/" /mnt/etc/mkinitcpio.conf
fi
arch-chroot /mnt mkinitcpio -p linux

syslinux-install_update -i -a -m -c /mnt
sed -i "s,UI menu.c32,#UI menu.c32," /mnt/boot/syslinux/syslinux.cfg
if [ "$encrypt" = true ] ; then
  sed -i "s,APPEND root=[a-z\/0-9]*,APPEND root=/dev/mapper/cryptroot cryptdevice=$root:cryptroot rootflags=subvol=__active/rootvol," /mnt/boot/syslinux/syslinux.cfg
else
  sed -i "s,APPEND root=[a-z\/0-9]*,APPEND root=$root rootflags=subvol=__active/rootvol," /mnt/boot/syslinux/syslinux.cfg
fi

mkdir /mnt/archlinux-setup
mount --bind "${dir}" /mnt/archlinux-setup
arch-chroot /mnt ansible-playbook --inventory-file=/archlinux-setup/inventory --limit=local /archlinux-setup/user.yml
umount /mnt/archlinux-setup
rm -r /mnt/archlinux-setup

pacman -Sy --noconfirm rsync
mkdir /mnt/home/user/.archlinux-setup
# copy setup folder excluding hidden files
rsync -av "${dir}/" --exclude=".*" /mnt/home/user/.archlinux-setup/
arch-chroot /mnt chown -R user:user /home/user/.archlinux-setup

arch-chroot /mnt systemctl enable dhcpcd
arch-chroot /mnt bash -c "echo yes" | pacman -Scc

echo ""
echo ""
echo "Setup complete, reboot, log in as user (password is user), and run ./.archlinux-setup/run.sh"
