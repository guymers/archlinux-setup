Boot machine with an Arch Linux dual iso and run

    curl -L https://git.io/archlinux-setup | tar --transform 's/-master//' -xz
    # modify $drive in `setup.sh` or set `ARCH_SETUP_DRIVE`
    ./archlinux-setup/setup.sh

If using secure boot follow these [instructions](https://unix.stackexchange.com/a/361772) to create the boot media:

    trizen -S preloader-signed
    sudo dd bs=4M if=archlinux-2022.04.05-x86_64.iso of=/dev/sd<X> conv=fsync oflag=direct status=progress
    sudo mount /dev/sd<X>2 /mnt
    sudo mv /mnt/EFI/BOOT/BOOTx64.EFI /mnt/EFI/BOOT/loader.efi
    sudo cp /usr/share/preloader-signed/PreLoader.efi /mnt/EFI/BOOT/bootx64.efi
    sudo cp /usr/share/preloader-signed/HashTool.efi /mnt/EFI/BOOT/
    sudo umount /mnt

And these [steps](https://wiki.archlinux.org/index.php?title=Secure_Boot&oldid=559440#Booting_an_install_media) when booting:
    
    Select OK
    In the HashTool main menu, select Enroll Hash, choose \loader.efi and confirm with Yes. Again, select Enroll Hash and archiso to enter the archiso directory, then select vmlinuz.efi and confirm with Yes. Then choose Exit to return to the boot device selection menu.
    In the boot device selection menu choose Arch Linux archiso x86_64 UEFI CD

Reboot, login in as `user` with password `user` and run

    ./.archlinux-setup/run.sh

Remove setup folder

    rm -r .archlinux-setup

### Notes
- Change root password or disable login
- Make sure cow is turned off for vm folders, see https://wiki.archlinux.org/title/Btrfs#Disabling_CoW
- Install any graphics drivers, check https://wiki.archlinux.org/index.php/Hardware_video_acceleration
- `cryptsetup  --allow-discards --persistent refresh root` to allow TRIM


### Development

Serve the repository via

    git daemon --base-path=.. --export-all --reuseaddr --informative-errors --verbose

Install git

    pacman --cachedir=/tmp -Sy --noconfirm git

Clone with

    git clone git://<ip>/archlinux-setup

Run the setup script

    ./archlinux-setup/setup.sh

Make sure you commit changes so they are cloned across.

The `packer` folder contains scripts which can also assist in testing.
