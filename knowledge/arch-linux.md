I had problems installing Arch Linux on a DELL Vostro 3500, when after installation, system wouldn't boot, with similar error:
```sh
ERROR: device 'UUID=<snip>' not found. Skipping fsck.
ERROR: Unable to find root device 'UUID=<snip>'.
You are being dropped to a recovery shell
    Type 'exit' to try and continue booting
sh: can't access tty: job control turned off
[rootfs /]# 
```

[this](https://forum.manjaro.org/t/error-device-uuid-device-uuid-not-found-skipping-fsck/70809/18) message helped me solve it, with steps as follows
1. I boot Arch Linux from the pendrive
2. I run `vim /etc/mkinitcpio.conf` and then add the `vmd` module:
3. `MODULES=(vmd)`, then I save and quit.
4. Run `mkinitcpio -P`
5. Reboot
