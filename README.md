Boot machine with archlinux dual iso
    pacman -S git
    git clone https://github.com/guymers/archlinux-setup
    cd archlinux-setup
    ./setup.sh

Reboot and run
    ./run.sh

### Audio
use alsamixer to set volume
sudo alsactl store

### Notes
make sure cow is turned off for virtualbox folders
