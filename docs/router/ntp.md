
`# pacman -S chrony`

`> /etc/chrony.conf`
```
server time.cloudflare.com iburst nts
server oregon.time.system76.com iburst nts
server paris.time.system76.com iburst nts
server virginia.time.system76.com iburst nts

authselectmode require

maxupdateskew 100

driftfile /var/lib/chrony/drift
ntsdumpdir /var/lib/chrony

leapsectz right/UTC
leapsecmode slew

makestep 1.0 3

allow 10.10.0.0/16
ratelimit interval 3 burst 8

mailonchange root 1
rtcsync
```

`# systemctl stop systemd-timesyncd`
`# systemctl disable systemd-timesyncd`

`# systemctl enable --now chronyd`
