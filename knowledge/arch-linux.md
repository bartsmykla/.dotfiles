# Arch Linux

## Installation

1. Confirm you have EFI support
   ```sh
   ls /sys/firmware/efi/efivars
   ```
2. Connect to the WIFI:
   ```sh
   iwctl --passphrase [passphrase] station [device] connect [SSID]
   ping 1.1.1.1 -c 4
   ```
3. Update time and date
   ```sh
   timedatectl set-ntp true
   timedatectl status
   ```
4. Create and format Linux partitions
   ```sh
   cfdisk
   ```
5. Format and mount the partitions
   ```sh
   mkfs.ext4 /dev/sda5
   mkswap /dev/sda6
   swapon /dev/sda6
   mount /dev/sda5 /mnt
   mount /dev/sda1 /mnt/efi
   ```
6. Install base system and other required Linux firmware packages
   ```sh
   pacstrap /mnt base linux linux-firmware
   ```
7. Generate `fstab` file
   ```sh
   genfstab -U /mnt >> /mnt/etc/fstab
   ```
8. Chroot into /mnt
   ```sh
   arch-chroot /mnt
   ```
9. Setup timezone
   ```sh
   ln -sf /usr/share/zoneinfo/Poland /etc/localtime
   wclock --systohc
   ```
10. Install `vim`
   ```sh
   pacman -Sy vim
   ```
11. Setup locale
   ```sh
   vim /etc/locale.gen
   locale-gen
   echo "LANG=EN_US.UTF-8" > /etc/locale.conf
   ```
12. Set polish keyboard
   ```sh
   loadkeys pl
   vim /etc/vconsole.conf
   # KEYMAP=pl
   # FONT=Lat2-Terminus16
   # FONT_MAP=8859-2
   ```
13. Configure network
   ```sh
   echo [hostname] > /etc/hostname
   echo "127.0.0.1  localhost" >> /etc/hosts
   echo "::1      localhost" >> /etc/hosts
   echo "127.0.1.1  [hostname].localdomain  [hostname]" >> /etc/hosts
   ```
14. Install and configure network manager
   ```sh
   pacman -Sy iwd
   vim /etc/iwd/main.conf
   # [General]
   # EnableNetworkConfiguration=true
   # [Network]
   # NameResolvingService=systemd
   ```
15. Create a regular user
   ```sh
   useradd -G wheel,audio,video -m bartsmykla
   passwd
   ```
16. Set root password
   ```sh
   passwd
   ```
17. Install GRUB bootloader, efibootmgr and os-prober
   ```sh
   pacman -S grub efibootmgr os-prober
   ```
18. Enable os-prober in configuration of GRUB
   ```sh
   vim /etc/default/grub
   # GRUB_DISABLE_OS_PROBER=false
   ```
19. Edit `/etc/mkinitcpio.conf` file
   - add the `vmd` module: `MODULES=(vmd)`
   - reorder `HOOKS` to have `block` hook before `autodetect`
      ```
      HOOKS="base udev block autodetect modconf filesystems keyboard fsck"
      ```
20. Install GRUB and generate it's config file
   ```sh
   grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   ```
21. Reboot
   ```sh
   exit
   reboot
   ```

## After installation

1. Install `sudo`
   ```sh
   pacman -S sudo
   ```
2. Add user `bartsmykla` to sudoers
   ```sh
   visudo
   # bartsmykla ALL=(ALL) NOPASSWD:ALL
   ```
3. Enable `iwd`
   ```sh
   systemctl enable --now iwd.service
   ```
4. Connect to the network
   ```sh
     iwctl --passphrase [passphrase] station [device] connect [SSID]
   ```

## Troubleshooting

### Problem: Cannot boot Arch after the successful installation

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
