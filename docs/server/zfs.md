
`# pacman -S linux-headers autoconf automake libtool`
`# paru -S zfs-dkms`

or `pacman -S linux-cachyos-zfs zfs-utils`

Make sure there is no `lockdown` in kernel boot command line.

Mount encrypted pools:
`> /etc/systemd/system/zfs-mount.service.d/override.conf`
```
[Service]
ExecStart=
ExecStart=/usr/bin/zfs mount -a -l
```

Mount on boot:
```
# systemctl enable zfs.target
# systemctl enable zfs-import-cache
# systemctl enable zfs-import.target
# systemctl enable zfs-mount.service
```

Enable email notifications:
```
# systemctl enable --now zfs-zed.service
```

Import an existing pool:
```
# zpool import -l -d /dev/disk/by-id data
```

Create a pool:
```
# zpool create -f \
  -o ashift=12 \
  -o autoexpand=on \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  -m /media/data data raid{z,z2} \ <dev/disk/by-id>
```

For general purpose file storage: `# zfs set recordsize=1024K data`

Make an encrypted dataset:
```
# mkdir /etc/secrets
# dd if=/dev/random of=/etc/secrets/data_key bs=1 count=32
# zfs create -o encryption=on -o keyformat=raw -o keylocation=file:///etc/secrets/data_key data/encrypted
```

Replace a disk:
```
# zpool offline data ata-XYZ
# zpool replace data ata-XYZ /dev/disk/by-id/ata-???
```

Scrub
start: `# zpool scrub data`
stop: `# zpool scrub -s data`

iostat: `# zpool iostat -vlyq 10 10`
