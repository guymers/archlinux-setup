#!/bin/bash
set -e
set -o pipefail

curl -L https://git.io/archlinux-setup | tar --transform 's/-master//' -xz
ARCH_SETUP_PACMAN_MIRROR='http://10.0.2.2:9129/repo/archlinux/$repo/os/$arch' \
ARCH_SETUP_DRIVE=/dev/vda \
  ./archlinux-setup/setup.sh

# inline the sudo password to avoid the prompt
sed -i '/^localhost/ s/$/ ansible_become_pass=user/' /mnt/home/user/.archlinux-setup/inventory

# enable ssh so packer can log in after reboot
arch-chroot /mnt systemctl enable sshd.service
reboot
