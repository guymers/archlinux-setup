
Change `rw` to `ro` in `/etc/kernel/cmdline` and rebuild the kernels `mkinitcpio -P`

### Updating

Mount the other `efi` partition at `/mnt`:
`# mount -t vfat -o umask=0077,rw,nodev,nosuid,noexec,nosymfollow /dev/disk/by-partuuid/2ce6c79d-4c9d-43b4-aaa4-256b4647656d /mnt`

Sync it with the current:
`# rsync -avh --stats --progress --delete /efi/EFI/ /mnt/EFI/`

Change the boot order to boot the "fallback" image and reboot:
`# efibootmgr -o 1,2,...`

Update

Change the boot order back
