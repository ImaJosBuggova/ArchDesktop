#!/usr/bin/env bash
set -euo pipefail

USER_LOCALE="$1"
KEYMAP="$2"
HOSTNAME="$3"
USERNAME="$4"
USER_PASSWORD="$5"
P3="$6"

echo "Setting up locales and keyboard layout..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "$USER_LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$USER_LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

echo "Setting hostname ($HOSTNAME)..."
echo "$HOSTNAME" > /etc/hostname

echo "Writing specialized kernel parameters..."
mkdir -p /etc/kernel
mkdir -p /boot/EFI/Linux
SYSTEM_UUID=$(blkid -s UUID -o value "$P3")
echo "root=UUID=${SYSTEM_UUID} rw" > /etc/kernel/cmdline

echo "Compiling Linux initial ramdisk environments..."
mkinitcpio -P

echo "Deploying systemd-boot..."
bootctl install

cat <<EOT > /boot/loader/loader.conf
default arch-linux
timeout 0
console-mode max
EOT

echo "Creating user account permissions..."
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd
echo "root:$USER_PASSWORD" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

echo "Enabling core system background services..."
systemctl enable NetworkManager
systemctl enable power-profiles-daemon
systemctl enable bluetooth
systemctl enable sddm