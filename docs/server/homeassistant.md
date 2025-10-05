
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
Image=ghcr.io/home-assistant/home-assistant:2025.10.1@sha256:9255033272ab8f7bede246109ea9e7302527faf3accbf2ba7ef619e2206107ad
Network=iotpods
IP=10.10.4.225
DNS=10.10.4.224
Environment=TZ=UTC
# homeassistant:homeassistant
Environment=PUID=968
Environment=PGID=968
Volume=/var/lib/hass:/config
Volume=/var/lib/hass/docker-run:/etc/services.d/home-assistant/run:ro
# for the ping integration to work
Sysctl=net.ipv4.ping_group_range='0 999'
Environment=PACKAGES=iputils
AddCapability=NET_RAW
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
ExecStart=/usr/bin/podman network connect --ip 10.10.6.225 localpods home-assistant

[Install]
WantedBy=home-assistant.service
```

`> /etc/containers/systemd/home-assistant-matter.container`
```
[Unit]
Description=home-assistant-matter
Wants=network-online.target
After=network-online.target
Before=home-assistant.service

[Container]
ContainerName=home-assistant-matter
HostName=home-assistant-matter
Image=ghcr.io/home-assistant-libs/python-matter-server:8.1.0@sha256:170aa093ce91c76cde4cc390918307590f0f5558fcec93f913af3cb019e6562a
Network=iotpods
IP=10.10.4.226
DNS=10.10.4.224
# homeassistant:homeassistant
User=968
Group=968
Volume=/var/lib/hass-matter:/data
NoNewPrivileges=true

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

`> /etc/systemd/system/home-assistant-matter-second-network.service`
```
[Unit]
PartOf=home-assistant-matter.service
After=home-assistant-matter.service

[Service]
Type=oneshot
ExecStart=/usr/bin/podman network connect --ip 10.10.6.226 localpods home-assistant-matter

[Install]
WantedBy=home-assistant-matter.service
```

`# systemctl daemon-reload`
`# systemctl enable home-assistant-second-network`
`# systemctl start home-assistant`
