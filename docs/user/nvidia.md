
Remove `kms` from `mkinitcpio` `HOOKS`

`> /etc/modprobe.d/nvidia.conf`
```
options nvidia_drm modeset=1
options nvidia_drm fbdev=1
options nvidia NVreg_EnableGpuFirmware=0
```


`> /etc/systemd/system/nvidia-power-limit.service`
```
[Unit]
Description=NVIDIA power limit

[Service]
Type=oneshot
ExecStartPre=/usr/bin/nvidia-smi --persistence-mode=1
ExecStart=/usr/bin/nvidia-smi --power-limit=210
```

`> /etc/systemd/system/nvidia-power-limit.timer`
```
[Unit]
Description=NVIDIA power limit on boot

[Timer]
OnBootSec=10

[Install]
WantedBy=timers.target
```

```
# pacman -S libva-nvidia-driver
```
