### Monitoring

`# pacman -S smartmontools hddtemp`

`> /etc/smartd.conf`
```
DEVICESCAN -H -C 0 -U 0 -m root
```

`# systemctl enable --now smartd`

### Testing

Long test: `# smartctl -t long /dev/sd?`

Short test: `# smartctl -t short /dev/sd?`

Destructive test: `# badblocks -wsv /dev/sd?`

Destructive test (single pass): `# badblocks -wsvt random /dev/sd?`
