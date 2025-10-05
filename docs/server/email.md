
`# pacman -S opensmtpd s-nail`

`> /etc/smtpd/aliases`
```
root: <email>@custom.domain
user: <email>@custom.domain
```

`> /etc/smtpd/virtuals`
```
notification@email.local  <email>@custom.domain
```

`> /etc/smtpd/secrets`
```
gmail <email>@custom.domain:<password>
```

`# chmod 600 /etc/smtpd/secrets`

`> /etc/smtpd/smtpd.conf`
```
table aliases file:/etc/smtpd/aliases
table secrets file:/etc/smtpd/secrets
table virtuals file:/etc/smtpd/virtuals

listen on 0.0.0.0

action "local" maildir alias <aliases>
action "virtual" maildir virtual <virtuals>
action "relay" relay host smtp+tls://gmail@smtp.gmail.com:587 auth <secrets>

accept from any for domain <vdomains> virtual <vusers> deliver to maildir

match for local action "local"
match from src x.x.x.x/24 for domain email.local action "virtual"
match from src x.x.x.x/24 for any action "local"
match from local for any action "relay"
```

`# systemctl enable --now smtpd`

On other servers:

`> /etc/smtpd/smtpd.conf`
```
table aliases file:/etc/smtpd/aliases

listen on localhost

action "relay" relay host smtp://x.x.x.x

match from local action "relay"
```

`# systemctl enable --now smtpd`
