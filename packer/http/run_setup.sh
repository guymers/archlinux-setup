#!/bin/bash
set -e
set -o pipefail

ARCH_SETUP_PACMAN_MIRROR='http://10.0.2.2:7878/$repo/os/$arch' \
ARCH_SETUP_DRIVE=/dev/vda \
ARCH_SETUP_DRIVE_MIRROR=/dev/vdb \
  ./setup.sh

# enable ssh so packer can log in after reboot
arch-chroot /mnt systemctl enable sshd.service
reboot
