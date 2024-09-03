
Remove `kms` from `mkinitcpio` `HOOKS`

`> /etc/modeset.d/nvidia.conf`
```
options nvidia_drm modeset=1
options nvidia_drm fbdev=1
options nvidia NVreg_EnableGpuFirmware=0
```
