
`# pacman -S podman`

Use brtfs for container volumes:

`> /etc/containers/storage.conf`
```
...
driver = "btrfs"
...
```

Create a macvlan:

```
# podman network create -d macvlan \
  -o parent=lan \
  --subnet=10.10.1.0/24 \
  --ip-range=10.10.1.210-10.10.1.240 \
  --ipam-driver=host-local \
  lanpods
```
