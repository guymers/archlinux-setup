
Create a wildcard SSL certificate:
`# pacman -S certbot-dns-cloudflare`

`> /etc/certbot/cloudflare.ini`
```
dns_cloudflare_api_token = TOKEN
```

`# chmod 600 /etc/certbot/cloudflare.ini`

`# certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/certbot/cloudflare.ini -d '*.domain.example.com'`

`> /etc/systemd/system/certbot-renew.timer.d/override.conf`
```
[Timer]
OnCalendar=weekly
```

`> /etc/systemd/system/certbot-renew.service.d/hardening.conf`
```
[Service]
NoNewPrivileges=true
PrivateDevices=true
PrivateTmp=true
PrivateUsers=true
ProtectControlGroups=true
ProtectHome=true
ProtectHostname=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectProc=invisible
ProtectSystem=strict
RemoveIPC=true
ReadOnlyPaths=/etc/certbot
ReadWritePaths=/etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true
```

`# systemctl enable --now certbot-renew.timer`

Set up a reverse proxy:
`# pacman -S caddy`

`> /etc/caddy/Caddyfile`
```
*.domain.example.com {
  tls /etc/letsencrypt/live/domain.example.com/cert.pem /etc/letsencrypt/live/domain.example.com/privkey.pem
}

ha.domain.example.com {
  reverse_proxy X:8123
}

unifi.domain.example.com {
  reverse_proxy Y:8443 {
    transport http {
      tls_insecure_skip_verify
    }
  }
}
```

`> /etc/letsencrypt/renewal-hooks/deploy/caddy.sh`
```
#!/bin/sh
set -e

setfacl -m u:caddy:rx /etc/letsencrypt/{archive,live}
setfacl -m u:caddy:r /etc/letsencrypt/archive/domain.example.com/privkey*
setfacl -m u:caddy:r /etc/letsencrypt/live/domain.example.com/privkey.pem

systemctl reload caddy
```

`# systemctl enable --now caddy`
