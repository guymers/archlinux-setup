
Create a user:
`> /etc/sysusers.d/home-assistant.conf`
```
u hass - "Home Assistant" /var/lib/hass
```
`# systemd-sysusers`

Create config directories:
`> /etc/tmpfiles.d/home-assistant.conf`
```
d /var/lib/hass 0750 hass hass
```
`# systemd-tmpfiles --create`

Allow dropping root:
`# curl -o /var/lib/hass/docker-run https://raw.githubusercontent.com/tribut/homeassistant-docker-venv/e4bc39ecdf5ac8afe3ff62ae3cb14419dbda65fd/run`
`# chmod +x /var/lib/hass/docker-run`

`> /etc/containers/systemd/home-assistant.container`
```
[Unit]
Description=home-assistant
Wants=network-online.target
After=network-online.target

[Container]
ContainerName=home-assistant
HostName=home-assistant
Image=ghcr.io/home-assistant/home-assistant:2024.8.3
Network=iotpods
IP=10.10.4.225
DNS=10.10.4.224
Environment=TZ=UTC
# homeassistant:homeassistant
Environment=PUID=968
Environment=PGID=968
Volume=/var/lib/hass:/config
Volume=/var/lib/hass/docker-run:/etc/services.d/home-assistant/run:ro
NoNewPrivileges=true

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

`> /etc/systemd/system/home-assistant-second-network.service`
```
[Unit]
PartOf=home-assistant.service
After=home-assistant.service

[Service]
Type=oneshot
ExecStart=/usr/bin/podman network connect --ip 10.10.6.215 localpods home-assistant

[Install]
WantedBy=home-assistant.service
```

`# systemctl daemon-reload`
`# systemctl enable home-assistant-second-network`
`# systemctl start home-assistant`
