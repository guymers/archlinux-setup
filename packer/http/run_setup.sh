#!/bin/bash
set -e
set -o pipefail

ARCH_SETUP_DRIVE=/dev/vda ./setup.sh

# enable ssh so packer can log in after reboot
arch-chroot /mnt systemctl enable sshd.service
reboot
