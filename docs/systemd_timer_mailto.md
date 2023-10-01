
https://wiki.archlinux.org/title/Systemd/Timers#MAILTO

`> /usr/local/bin/systemd-status-email`
```
#!/bin/sh

/usr/bin/sendmail -t <<ERRMAIL
To: $1
From: systemd <root@$HOSTNAME>
Subject: $2
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset=UTF-8

$(systemctl status --full "$2")
ERRMAIL
```
`# chmod +x /usr/local/bin/systemd-status-email`


`> /etc/systemd/system/status-email@.service`
```
[Unit]
Description=status email for %i

[Service]
Type=oneshot
ExecStart=/usr/local/bin/systemd-status-email root %i
User=postfix
Group=systemd-journal
PrivateTmp=true
TimeoutSec=300
```
