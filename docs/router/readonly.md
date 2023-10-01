
Change `rw` to `ro` in `/etc/kernel/cmdline` and rebuild the kernels `mkinitcpio -P`

### Updating

Mount the other `efi` partition at `/mnt`:
`# mount -t vfat -o umask=0077,rw,nodev,nosuid,noexec,nosymfollow /dev/disk/by-partuuid/64ffa332-3309-4d46-9d27-b022fab0f23e /mnt`

Sync it with the current:
`# rsync -avh --stats --progress --delete /efi/ /mnt/`

Change the boot order to boot the "fallback" image and reboot:
`# efibootmgr -o 1,2,...`

Update

Change the boot order back
