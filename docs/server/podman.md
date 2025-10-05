
`# pacman -S podman`

Use brtfs for container volumes:

`> /etc/containers/storage.conf`
```
...
driver = "btrfs"
...
```

`> /etc/containers/containers.conf`
```
...
pasta_options = [ "--ipv4-only" ]
...
```

Create a macvlan:

```
# podman network create -d macvlan \
  -o parent=lan \
  -o metric=100 \
  --subnet=10.10.1.0/24 \
  --ip-range=10.10.1.225-10.10.1.238 \
  --ipam-driver=host-local \
  lanpods
```

```
# podman network create -d macvlan \
  -o parent=iot \
  -o metric=400 \
  --subnet=10.10.4.0/24 \
  --ip-range=10.10.4.225-10.10.4.238 \
  --ipam-driver=host-local \
  iotpods
```

```
# podman network create -d macvlan \
  -o parent=local \
  -o metric=600 \
  --subnet=10.10.6.0/24 \
  --ip-range=10.10.6.225-10.10.6.238 \
  --ipam-driver=host-local \
  localpods
```
