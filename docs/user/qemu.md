
`> /etc/systemd/network/11-bridge-inherit-mac.link`
```
[Match]
Name=virbr0

[Link]
MACAddressPolicy=none
```

`> /etc/systemd/network/11-virbr0.netdev`
```
[NetDev]
Name=virbr0
Kind=bridge
MACAddress=none
```

`> /etc/systemd/network/12-virbr0-en.network`
```
[Match]
Name=en*
Name=eth*

[Network]
Bridge=virbr0
```

`> /etc/systemd/network/12-virbr0.network`
```
[Match]
Name=virbr0

[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
LLMNR=no
MulticastDNS=resolve
```
