#!/usr/bin/env bash
set -euo pipefail

# Get Parameters
DISK_PATH="$1"
P1="$2"
P2="$3"
P3="$4"

echo "Calculating partitions..."
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
SWAP_SIZE="${TOTAL_RAM_MB}MiB"

echo "Wiping $DISK_PATH..."
sgdisk --zap-all "$DISK_PATH"

echo "Partitioning $DISK_PATH..."
sgdisk -n 1:0:+1024MiB -t 1:ef00 -c 1:"BOOT" "$DISK_PATH"
sgdisk -n 2:0:+"$SWAP_SIZE" -t 2:8200 -c 2:"SWAP" "$DISK_PATH"
sgdisk -n 3:0:0 -t 3:8300 -c 3:"SYSTEM" "$DISK_PATH"

echo "Informing the Linux kernel about partition layout changes..."
partprobe "$DISK_PATH" || true
udevadm trigger
udevadm settle
sleep 2

# Debug
parted -s "$DISK_PATH" print
sleep 2

echo "Formatting partitions..."
mkfs.vfat -F32 "$P1"
mkswap "$P2"
mkfs.ext4 -F "$P3"

echo "Mounting system roots..."
mount "$P3" /mnt
mkdir -p /mnt/boot
mount "$P1" /mnt/boot

echo "Detecting CPU..."
PROC=$(lscpu | grep -oP 'Vendor ID:\s+\K\w+')
if [ "$PROC" = "GenuineIntel" ]; then
    UCODE="intel-ucode"
    FW_CPU="linux-firmware-intel"
else
    UCODE="amd-ucode"
    FW_CPU="linux-firmware-amd linux-firmware-amdgpu"
fi
echo $PROC
sleep 1

echo ""
echo "Firmware setup"
pacstrap -K /mnt base linux $UCODE $FW_CPU sudo networkmanager xorg-server power-profiles-daemon

echo ""
echo "Audio setup"
pacstrap /mnt pipewire pipewire-audio pipewire-alsa pipewire-jack pipewire-pulse wireplumber bluez bluez-utils

echo ""
echo "KDE Setup"
pacstrap /mnt sddm sddm-kcm plasma-desktop plasma-pa plasma-nm  kde-cli-tools ttf-fira-sans ttf-fira-mono

echo ""
echo "Apps setup"
pacstrap /mnt dolphin ark konsole unrar unzip p7zip kdeconnect papirus-icon-theme firefox thunderbird plasma-systemmonitor kinfocenter

echo ""
echo "Generating fstab entries..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "UUID=$(blkid -s UUID -o value "$P2") none swap defaults 0 0" >> /mnt/etc/fstab