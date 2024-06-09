
`# pacman -S postfix s-nail`

`> /etc/postfix/aliases`
```
root: <email>@custom.domain
user: <email>@custom.domain
```

`# postalias /etc/postfix/aliases`

`# newaliases`

`# mkdir /etc/postfix/sasl`

`> /etc/postfix/sasl/sasl_passwd`
```
[smtp.gmail.com]:587 <email>@custom.domain:<password>
```

`# postmap /etc/postfix/sasl/sasl_passwd`

`# chmod 600 /etc/postfix/sasl/sasl_passwd*`

`> /etc/postfix/main.cf`
```
inet_interfaces = 127.0.0.1
relayhost = [smtp.gmail.com]:587
relay_domains = custom.domain
alias_maps = lmbd:/etc/postfix/aliases

smtp_sasl_auth_enable = yes
smtp_sasl_security_options = 
smtp_sasl_password_maps = lmdb:/etc/postfix/sasl/sasl_passwd
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

`# systemctl enable --now postfix`
