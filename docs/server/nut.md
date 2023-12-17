### UPS

`# pacman -S nut`

https://wiki.archlinux.org/title/Network_UPS_Tools

`> /etc/nut/ups.conf`
```
[ups]
  driver = usbhid-ups
  port = auto
```

`> /etc/nut/upsd.users`
```
[upsuser]
  password = password
  upsmon primary
  actions = SET
  instcmds = ALL
```

`# systemctl start --now nut-driver-enumerator.service`
`# systemctl start --now nut-server.service`

`# upscmd ups beeper.disable`

`> /etc/nut/upsmon.conf`
```
MONITOR ups@localhost 1 upsuser password primary
FINALDELAY 30
```

`# systemctl start --now nut-monitor.service`

`# systemctl enable nut.target`
`# systemctl enable nut-driver.target`
