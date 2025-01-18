

Add `systemd.volatile=overlay` to `/etc/kernel/cmdline` and rebuild the kernels `mkinitcpio -P`

`systemd.volatile=overlay`





TODO

Change `rw` to `ro` in `/etc/kernel/cmdline` and rebuild the kernels `mkinitcpio -P`

### Updating

Mount the other `efi` partition at `/mnt`:
`# mount -t vfat -o umask=0077,rw,nodev,nosuid,noexec,nosymfollow /dev/disk/by-partuuid/99fdb9f1-ed83-45a4-9a4e-2cf32730adde /mnt`

Sync it with the current:
`# rsync -avh --stats --progress --delete /efi/EFI/ /mnt/EFI/`

Change the boot order to boot the "fallback" image and reboot:
`# efibootmgr -o 1,2,...`

Update

Change the boot order back
