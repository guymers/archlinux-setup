Boot machine with archlinux dual iso

    pacman -Sy git
    git clone https://github.com/guymers/archlinux-setup
    ./archlinux-setup/setup.sh

Reboot, login in as ```user``` with password ```user``` and run

    ./.archlinux-setup/run.sh

### Audio
use alsamixer to set volume
```sudo alsactl store```

### Notes
make sure cow is turned off for virtualbox folders
