
To allow `<hostname>.local` to resolve modify `/etc/systemd/network/20-wired.network` and set `MulticastDNS` from `resolve` to `yes`

To use DHCP DNS remove `/etc/systemd/resolved.conf.d/cloudflare.conf`
