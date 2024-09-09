
`/lib/ld-linux-x86-64.so.2 --help | grep supported`

`gcc -march=native -Q --help=target 2>&1 | grep -Po "^\s+-march=\s+\K(\w+)\$"`

Install keyring
`sudo pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com`
`sudo pacman-key --lsign-key F3B607488DB35A47`

`sudo pacman -U https://mirror.cachyos.org/repo/x86_64/cachyos/pacman-6.1.0-7-x86_64.pkg.tar.zst`

`> /etc/pacman.d/cachyos-v4-mirrorlist`
```
Server = http://10.10.3.1:9129/repo/cachyos/$arch_v4/$repo
#Server = https://mirror.cachyos.org/repo/$arch_v4/$repo
#Server = https://aur.cachyos.org/repo/$arch_v4/$repo
```

`> /etc/pacman.d/cachyos-mirrorlist`
```
Server = http://10.10.3.1:9129/repo/cachyos/$arch/$repo
#Server = https://mirror.cachyos.org/repo/$arch/$repo
#Server = https://aur.cachyos.org/repo/$arch/$repo
```

`> /etc/pacman.conf`
```
[cachyos-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist
[cachyos-core-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist
[cachyos-extra-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist
[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
```

If only `x86-64-v4` replace `znver4` with `v4`
