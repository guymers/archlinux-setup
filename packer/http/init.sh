#!/bin/bash
set -e
set -o pipefail

wget -s https://git.io/archlinux-setup | tar --transform 's/-master//' -xz
./archlinux-setup/setup.sh

# inline the sudo password to avoid the prompt
sed -i '/^localhost/ s/$/ ansible_become_pass=user/' /mnt/home/user/.archlinux-setup/inventory

# enable ssh so packer can log in after reboot
arch-chroot /mnt systemctl enable sshd.service
reboot
