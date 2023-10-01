
`# pacman -S anything-sync-daemon`

`> /etc/asd.conf`
```
WHATTOSYNC=('/var/cache' '/var/log')
VOLATILE="/tmp"
USE_OVERLAYFS="yes"

USE_BACKUPS="no"
BACKUP_LIMIT=1
```

`> /etc/modules-load.d/overlay.conf`
```
overlay
```

`# systemctl enable --now asd.service`
