
`# pacman -S pacoloco`

`> /etc/pacoloco.yaml`
```
#port: 9129
#cache_dir: /var/cache/pacoloco
purge_files_after: 604800 # 7 days
download_timeout: 120 # seconds
repos:
  archlinux:
    urls:
      - https://sydney.mirror.pkgbuild.com/
      - https://mirror.aarnet.edu.au/pub/archlinux/
      - https://mirror.fsmg.org.nz/archlinux/
prefetch:
  cron: 0 0 3 * * * * # 3am every day
  ttl_unaccessed_in_days: 14
  ttl_unupdated_in_days: 30
```

`# systemctl enable --now pacoloco.service`
