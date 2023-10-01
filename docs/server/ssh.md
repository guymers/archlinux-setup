
`> /etc/ssh/sshd_config.d/custom.conf`
```
PermitRootLogin no
PasswordAuthentication no
AllowUsers user@10.10.1.0/24 user@10.10.3.0/24
AuthorizedKeysFile /etc/ssh/%u/authorized_keys
```

`# systemctl enable --now sshd`
