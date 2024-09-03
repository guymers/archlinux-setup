
https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation

`# btrfs subvolume create _/@swap`

`# btrfs filesystem mkswapfile --size <ram>g --uuid clear /swap/file`

`# swapon /swap/file`

`> /etc/systemd/system/swap.mount`
```
[Unit]
Before=local-fs.target
After=-.mount

[Mount]
What=/dev/mapper/cryptroot
Where=/swap
Type=btrfs
Options=subvol=_/@swap
```

`> /etc/systemd/system/swap-file.swap`
```
[Swap]
What=/swap/file
TimeoutSec=60s
```


--- shouldnt be needed if using systemd mkinitipic hooks


offset:
`# btrfs inspect-internal map-swapfile -r /swap/file`

update kernel cmdline:
`resume=/dev/mapper/cryptroot resume_offset=<offset>`
