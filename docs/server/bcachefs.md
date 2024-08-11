
`# pacman -S bcachefs-tools`

write-back cache:
```
# bcachefs format \
  --compression=zstd:1 \
  --background_compression=zstd:1 \
  --encrypted \
  --replicas=2 \
  --label=hdd.hdd1 /dev/sda \
  --label=hdd.hdd2 /dev/sdb \
  --label=hdd.hdd3 /dev/sdc \
  --label=hdd.hdd4 /dev/sdd \
  --label=hdd.hdd5 /dev/sde \
  --discard \
  --label=ssd.ssd1 /dev/nvme0n1 \
  --label=ssd.ssd2 /dev/nvme1n1 \
  --foreground_target=ssd \
  --promote_target=ssd \
  --background_target=hdd
```

`> /etc/bcachefs/key`
```
<passphrase>
```

`> /etc/systemd/system/unlock-media-data.service`
```
[Unit]
StopWhenUnneeded=true
Before=umount.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/sbin/bcachefs unlock -f /etc/bcachefs/key /dev/disk/by-uuid/<External UUID>
```

`> /etc/systemd/system/media-data.mount`
```
[Unit]
Requires=unlock-media-data.service
After=unlock-media-data.service

[Mount]
What=/dev/disk/by-uuid/<External UUID>
Where=/media/data
Type=bcachefs
```

`> /etc/systemd/system/media-data.automount`
```
[Automount]
Where=/media/data
TimeoutIdleSec=60

[Install]
WantedBy=local-fs.target
```
`# systemctl enable media-data.automount`

usage:
`# bcachefs fs usage -h /media/data`

errors:
`cat /sys/fs/bcachefs/<External UUID>/dev-*/io_errors`
