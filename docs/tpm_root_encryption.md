```
# systemd-cryptenroll --tpm2-device=list
# systemd-cryptenroll /dev/sda2 --wipe-slot=empty --recovery-key
# systemd-cryptenroll /dev/sda2 --tpm2-device=auto --tpm2-pcrs=7
# systemd-cryptenroll /dev/sda2 --wipe-slot=password
```

`> /etc/crypttab.initramfs`
```
root  UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX  none  tpm2-device=auto
```

`# mkinitcpio -P`
