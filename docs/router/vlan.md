
Rename wan interface:

`> /etc/systemd/network/01-wan.link`
```
[Match]
MACAddress=<address>
Type=ether

[Link]
Name=wan
Description=<desc>
```

Repeat for other ports.

Configure how `wan` connects:

`> /etc/systemd/network/10-wan.network`
```
[Match]
Name=wan

[Network]
DHCP=yes
LinkLocalAddressing=no
```

Make a `/etc/systemd/network/11-vlan-<name>.netdev` for each vlan:
```
[NetDev]
Name=num9
Kind=vlan
MACAddress=00:00:00:00:00:09

[VLAN]
Id=9
```

Make a `/etc/systemd/network/11-vlan-<name>.network` for each vlan:
```
[Match]
Name=num9

[Network]
Address=10.10.9.1/24
ConfigureWithoutCarrier=yes
DHCPServer=yes
IPForward=yes
IPMasquerade=yes
LinkLocalAddressing=no

[Link]
RequiredForOnline=no

[DHCPServer]
PoolOffset=100
PoolSize=100
EmitDNS=yes
DNS=10.10.9.1
EmitNTP=yes
NTP=10.10.9.1

[DHCPServerStaticLease]
MACAddress=<mac>
Address=10.10.9.1
```

Make a bridge:

`> /etc/systemd/network/12-vlan-bridge.netdev`
```
[NetDev]
Name=vlans
Kind=bridge
MACAddress=00:00:00:00:00:00

[Bridge]
VLANFiltering=yes
DefaultPVID=1
```

`> /etc/systemd/network/12-vlan-bridge.network`
```
[Match]
Name=vlans

[Network]
ConfigureWithoutCarrier=yes
IPForward=yes
IPMasquerade=yes
LinkLocalAddressing=no

VLAN=9
...

[BridgeVLAN]
VLAN=1

[BridgeVLAN]
VLAN=9

...
```

Assign interfaces:

`> /etc/systemd/network/21-vlan-interfaces.network`
```
[Match]
Name=port*

[Network]
Bridge=vlans
LinkLocalAddressing=no

[BridgeVLAN]
VLAN=1
PVID=1
EgressUntagged=1

[BridgeVLAN]
VLAN=9

...
```
