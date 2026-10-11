#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script with sudo or as root."
    exit 1
fi

MODULE_DIR="$(dirname "$(readlink -f "$0")")/.modules"

# --- Keyboard Layout ---
read -p "Enter your keyboard layout (default: us): " KEYMAP
KEYMAP=${KEYMAP:-"us"}

loadkeys $KEYMAP

# --- Interactive Network Validation Verification ---
echo "Validating internet connectivity..."
if ! ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
    bash "$MODULE_DIR/connect_to_wifi.sh"
fi

# --- Storage Discovery ---
echo ""
echo "--- Storage Discovery ---"
lsblk -d -n -o NAME,SIZE,MODEL | grep -v "loop"
echo ""
read -p "Enter the target disk name to WIPE and install to (e.g., sda, nvme0n1): " TARGET_DISK
DISK_PATH="/dev/$TARGET_DISK"

if [ ! -b "$DISK_PATH" ]; then
    echo "Error: Device $DISK_PATH does not exist."
    exit 1
fi

if [[ "$DISK_PATH" == *"nvme"* || "$DISK_PATH" == *"mmcblk"* ]]; then
    P1="${DISK_PATH}p1"
    P2="${DISK_PATH}p2"
    P3="${DISK_PATH}p3"
else
    P1="${DISK_PATH}1"
    P2="${DISK_PATH}2"
    P3="${DISK_PATH}3"
fi

# --- Region & Localization ---
echo ""
echo "--- Region & Localization ---"
read -p "Enter your desired locale (default: en_US.UTF-8): " USER_LOCALE
USER_LOCALE=${USER_LOCALE:-"en_US.UTF-8"}

# --- User Credentials ---
echo ""
echo "--- User Credentials ---"
read -p "Enter hostname for this PC: " HOSTNAME
read -p "Enter username for the new account: " USERNAME
read -s -p "Enter password for $USERNAME: " USER_PASSWORD
echo ""

# --- Orchestrate Sub-Module Execution ---
echo ""
echo "========================================="
echo " INSTALLATION STARTED"
echo "========================================="
echo ""

echo "Executing Module: Base OS Installation..."
bash "$MODULE_DIR/base_install.sh" "$DISK_PATH" "$P1" "$P2" "$P3"

echo "Executing Module: Internal Configurations..."
cat <<EOT > /mnt/etc/mkinitcpio.d/linux.preset
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
default_uki="/boot/EFI/Linux/arch-linux.efi"
default_options="--cmdline /etc/kernel/cmdline"
EOT
cp "$MODULE_DIR/chroot_config.sh" /mnt/chroot_config.sh
arch-chroot /mnt /bin/bash /chroot_config.sh "$USER_LOCALE" "$KEYMAP" "$HOSTNAME" "$USERNAME" "$USER_PASSWORD" "$P3"
rm -f /mnt/chroot_config.sh

echo "Executing Module: Video Setup..."
cp "$MODULE_DIR/video_setup.sh" /mnt/video_setup.sh
arch-chroot /mnt /bin/bash /video_setup.sh
rm -f /mnt/video_setup.sh

echo "Executing Module: Theme Setup..."
cp "$MODULE_DIR/kde_theme.sh" /mnt/kde_theme.sh
cp "$(dirname "$(readlink -f "$0")")/wallpaper.jpg" /mnt/tmp_wallpaper.jpg
cp "$(dirname "$(readlink -f "$0")")/Bibata-Modern-Ice.tar.xz" /mnt/tmp_bibata.tar.xz
cp "$(dirname "$(readlink -f "$0")")/arch-crystal.svg" /mnt/tmp_icon.svg
arch-chroot /mnt /bin/bash /kde_theme.sh "$USERNAME"
rm -rf /mnt/kde_theme.sh /mnt/tmp_wallpaper.jpg /mnt/tmp_bibata.tar.xz /mnt/tmp_icon.svg

echo "Finalizing setup and unmounting variables..."
umount -R /mnt || true
swapoff "$P2" || true

echo ""
echo "========================================="
echo " INSTALLATION COMPLETED"
echo "========================================="
echo ""

for i in {5..1}; do
    echo -ne " Rebooting in $i seconds...\r"
    sleep 1
done

reboot