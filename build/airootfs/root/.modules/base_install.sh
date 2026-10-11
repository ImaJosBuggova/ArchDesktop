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

echo "Running pacstrap core utilities..."
pacstrap -K /mnt base linux linux-firmware sudo networkmanager xorg-server power-profiles-daemon pipewire pipewire-audio pipewire-alsa pipewire-jack pipewire-pulse wireplumber plasma-pa bluez bluez-utils plasma-desktop sddm kde-cli-tools plasma-nm plasma-systemmonitor sddm-kcm firefox thunderbird dolphin ark konsole unrar unzip p7zip lrzip lz4 kdeconnect papirus-icon-theme ttf-fira-sans ttf-fira-mono

echo "Generating fstab entries..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "UUID=$(blkid -s UUID -o value "$P2") none swap defaults 0 0" >> /mnt/etc/fstab