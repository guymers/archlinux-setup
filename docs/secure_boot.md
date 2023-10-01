Put Secure Boot into "Setup Mode" via BIOS

`# bootctl status | grep "Secure Boot"`
```
...
Secure Boot: disabled (setup)
...
```

Check to see if Microsoft keys are needed due by firmware that loads during boot:

```
# cat /sys/kernel/security/tpm0/binary_bios_measurements > /tmp/tpmlog.bin
# pacman -S tpm2-tools
tpm2_eventlog /tmp/tpmlog.bin > /tmp/tpmlog.yml
grep EV_EFI_BOOT_SERVICES_DRIVER /tmp/tpmlog.yml
```

If lines are output call `enroll-keys` with the `--microsoft` flag

```
# pacman -S sbctl
# sbctl create-keys
# sbctl enroll-keys
# sbctl sign -s /efi/EFI/Linux/arch-linux.efi
# sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi
```

Add `lockdown=integrity` to `/etc/kernel/cmdline`

Reboot and enable Secure Boot in the BIOS
