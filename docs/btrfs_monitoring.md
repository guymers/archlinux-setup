
`> /etc/systemd/system/btrfs-monitoring@.timer`
```
[Unit]
Description=Daily btrfs stats check on %f

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

`> /etc/systemd/system/btrfs-monitoring@.service`
```
[Unit]
Description=Btrfs stats on %f
ConditionPathIsMountPoint=%f
RequiresMountsFor=%f
OnFailure=status-email@%n.service

[Service]
Nice=19
IOSchedulingClass=idle
KillSignal=SIGINT
ExecStart=/usr/bin/btrfs device stats --check %f
```

`# systemctl enable btrfs-monitoring@-.timer`
