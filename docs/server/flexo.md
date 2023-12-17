
`# mkdir /var/cache/flexo`
`# chown 65534:65534 /var/cache/flexo`

`> /etc/containers/systemd/flexo.container`
```
[Unit]
Description=flexo (pacman caching)
Wants=network-online.target
After=network-online.target

[Container]
ContainerName=flexo
HostName=flexo
Image=docker.io/nroi/flexo:1.6.9
Network=lanpods
IP=10.10.1.230
DNS=10.10.1.210
# nobody:nogroup
User=65534
Group=65534
Environment=FLEXO_LISTEN_IP_ADDRESS=0.0.0.0
Environment=FLEXO_NUM_VERSIONS_RETAIN=2
Environment=FLEXO_MIRROR_SELECTION_METHOD=predefined
Environment=FLEXO_MIRRORS_PREDEFINED="['https://mirror.aarnet.edu.au/pub/archlinux/','https://sydney.mirror.pkgbuild.com/','https://mirror.fsmg.org.nz/archlinux/']"
Volume=/var/cache/flexo:/var/cache/flexo
NoNewPrivileges=true

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

`# systemctl daemon-reload`
`# systemctl start flexo`
