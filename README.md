Boot machine with archlinux dual iso

Increase the [size of cowspace](https://bbs.archlinux.org/viewtopic.php?pid=1592688#p1592688)

    mount -o remount,size=1G /run/archiso/cowspace
    pacman --cachedir=/tmp -Sy --noconfirm git
    git clone https://github.com/guymers/archlinux-setup
    ./archlinux-setup/setup.sh

Reboot, login in as ```user``` with password ```user``` and run

    ./.archlinux-setup/run.sh

Remove setup folder

    rm -r .archlinux-setup

### Audio
Use alsamixer to set volume
```sudo alsactl store```

### Notes
- Change root password or disable login
- Make sure cow is turned off for VirtualBox folders


### Development

Serve the repository via

    git daemon --base-path=.. --export-all --reuseaddr --informative-errors --verbose

Clone with

    git clone git://<ip>/archlinux-setup

Make sure you commit changes so they are cloned across.
