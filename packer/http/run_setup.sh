#!/bin/bash
set -e
set -o pipefail

./setup.sh

# enable ssh so packer can log in after reboot
arch-chroot /mnt systemctl enable sshd.service
reboot
