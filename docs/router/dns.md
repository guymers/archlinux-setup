
`# pacman -S unbound`

`> /etc/unbound/unbound.conf`
```
include: "/etc/unbound/custom.conf"
```

`> /etc/unbound/custom.conf`
```
server:
  interface: 0.0.0.0@53
  interface: ::0@53
  port: 53

  access-control: 127.0.0.0/8 allow  # (allow queries from the local host)
  access-control: 10.10.0.0/16 allow
  
  prefetch: yes
  cache-min-ttl: 600 # 10m
  cache-max-ttl: 86400 # 24h

  # Protocols
  do-ip4: yes
  do-ip6: yes
  do-udp: yes
  do-tcp: yes

  # Hardening
  use-caps-for-id: yes
  hide-identity: yes
  hide-version: yes
  aggressive-nsec: yes
  rrset-roundrobin: yes
  tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"
  harden-glue: yes
  harden-dnssec-stripped: yes
  
  # Enforce privacy of these addresses
  private-address: 10.0.0.0/8
  private-address: 172.16.0.0/12
  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: fd00::/8
  private-address: fe80::/10
  private-address: ::ffff:0:0/96

  include: /etc/unbound/block.conf

# Upstream Server
forward-zone:
  name: "."
  forward-tls-upstream: yes
  forward-addr: 1.0.0.1@853#one.one.one.one
  forward-addr: 1.1.1.1@853#one.one.one.one
  forward-addr: 2606:4700:4700::1111@853#one.one.one.one
  forward-addr: 2606:4700:4700::1001@853#one.one.one.one
  forward-addr: 8.8.4.4@853#dns.google
  forward-addr: 8.8.8.8@853#dns.google
  forward-addr: 2001:4860:4860::8888@853#dns.google
  forward-addr: 2001:4860:4860::8844@853#dns.google
```

`# /etc/unbound/block.conf`
```
local-zone: "doubleclick.com" redirect
local-data: "doubleclick.com A 0.0.0.0"
```

`# systemctl stop systemd-resolved`
`# systemctl disable systemd-resolved`

`# rm /etc/resolv.conf`

`> /etc/resolv.conf`
```
nameserver ::1
nameserver 127.0.0.1
options trust-ad
```

`# chattr +i /etc/resolv.conf`

`# systemctl enable --now unbound`
