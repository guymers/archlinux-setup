
`# pacman -S firewalld`

`> /etc/firewalld/firewalld.conf`
```
DefaultZone=drop
CleanupOnExit=no
LogDenied=all
```

`> /etc/firewalld/zones/wan.xml`
```
<?xml version="1.0" encoding="utf-8"?>
<zone target="DROP">
  <interface name="wan"/>
  <masquerade/>
</zone>
```

`> /etc/firewalld/zones/lan.xml`
```
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <interface name="lan"/>
  <service name="ssh"/>
  <service name="ntp"/>
  <service name="dns"/>
  <service name="dhcp"/>
  <service name="dhcpv6"/>
  <service name="dhcpv6-client"/>
  <forward/>
</zone>
```

Force DNS through local DNS server:

`> /etc/firewalld/zones/vlan-iot.xml`
```
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <interface name="iot"/>
  <service name="ntp"/>
  <service name="dns"/>
  <service name="dhcp"/>
  <service name="dhcpv6"/>
  <service name="dhcpv6-client"/>
  <rule family="ipv4" priority="1">
    <source invert="true" address="10.10.4.1"/>
    <forward-port port="53" protocol="tcp" to-port="53" to-addr="10.10.4.1"/>
  </rule>
  <rule family="ipv4" priority="2">
    <source invert="true" address="10.10.4.1"/>
    <forward-port port="53" protocol="udp" to-port="53" to-addr="10.10.4.1"/>
  </rule>
  <forward/>
</zone>
```

`> /etc/firewalld/policies/internet-access.xml`
```
<?xml version="1.0" encoding="utf-8"?>
<policy target="ACCEPT">
  <ingress-zone name="lan"/>
  <egress-zone name="wan"/>
</policy>
```

Disable external DNS:

`> /etc/firewalld/policies/iot-dns.xml`
```
<?xml version="1.0" encoding="utf-8"?>
<policy target="ACCEPT">
  <ingress-zone name="vlan-iot"/>
  <egress-zone name="wan"/>
  <rule family="ipv4" priority="11">
    <source invert="true" address="10.10.4.1"/>
    <port port="53" protocol="tcp"/>
    <drop/>
  </rule>
  <rule family="ipv4" priority="12">
    <source invert="true" address="10.10.4.1"/>
    <port port="53" protocol="udp"/>
    <drop/>
  </rule>
</policy>
```

`# systemctl enable --now firewalld`

To see rules: `nft list ruleset`

