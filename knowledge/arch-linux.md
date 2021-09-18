# Arch Linux

## Problem: Cannot boot Arch after the successful installation

I had problems installing Arch Linux on a DELL Vostro 3500, when after installation, system wouldn't boot, with similar error:
```sh
ERROR: device 'UUID=<snip>' not found. Skipping fsck.
ERROR: Unable to find root device 'UUID=<snip>'.
You are being dropped to a recovery shell
    Type 'exit' to try and continue booting
sh: can't access tty: job control turned off
[rootfs /]# 
```

[this](https://forum.manjaro.org/t/error-device-uuid-device-uuid-not-found-skipping-fsck/70809/18) and [this](https://itectec.com/superuser/unable-to-find-root-device-on-a-fresh-archlinux-install/) messages helped me solve it, with steps as follows
1. I boot Arch Linux from the pendrive
2. Edit `/etc/mkinitcpio.conf` file
   - add the `vmd` module: `MODULES=(vmd)`
   - reorder `HOOKS` to have `block` hook before `autodetect`
      ```
      HOOKS="base udev block autodetect modconf filesystems keyboard fsck"
      ```
5. Run `mkinitcpio -P`
6. Reboot
