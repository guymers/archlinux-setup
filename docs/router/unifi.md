
Create a user:
`> /etc/sysusers.d/unifi.conf`
```
u unifi - "Ubiquiti UniFi Controller" /var/lib/unifi
```
`# systemd-sysusers`

Create data and log directories:

`> /etc/tmpfiles.d/unifi.conf`
```
d /var/lib/unifi 0750 unifi unifi
d /var/log/unifi 0750 unifi unifi
d /run/unifi 0750 unifi unifi
```
`# systemd-tmpfiles --create`

For syslog logging from devices:

`# pacman -S socat`

`> /etc/systemd/system/unifi-syslog.service`
```
[Service]
Restart=always
ExecStart=/usr/bin/socat -u UDP-RECV:515 STDOUT

[Install]
WantedBy=default.target
```

`> /etc/containers/systemd/unifi.container`
```
[Unit]
Description=unifi
Wants=network-online.target
After=network-online.target
After=unifi-syslog.service
Requires=unifi-syslog.service

[Container]
ContainerName=unifi
HostName=unifi
Image=ghcr.io/guymers/unifi:v9.3.45
Network=lanpods
IP=10.10.1.238
DNS=10.10.1.224
# unifi:unifi
User=970
Group=970
Volume=/var/lib/unifi:/unifi/data
Volume=/var/log/unifi:/unifi/log
Volume=/run/unifi:/unifi/run
NoNewPrivileges=true
HealthCmd="/usr/local/bin/docker-healthcheck.sh || exit 1"
HealthInterval=300s
HealthOnFailure=stop

[Service]
Restart=on-failure

[Install]
#WantedBy=default.target
```

`# systemctl daemon-reload`
`# systemctl start unifi`
