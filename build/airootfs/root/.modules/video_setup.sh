#!/usr/bin/env bash
set -euo pipefail

echo "Scanning PCI hardware buses for GPU signatures..."

VGA_DATA=$(lspci | grep -Ei "vga|3d" | tr '[:upper:]' '[:lower:]')

DRIVERS=()
HAS_INTEL=0
HAS_AMD=0
HAS_NVIDIA=0

if echo "$VGA_DATA" | grep -q "intel"; then HAS_INTEL=1; DRIVERS+=("mesa" "intel-media-driver"); fi
if echo "$VGA_DATA" | grep -q "amd/ati"; then HAS_AMD=1; DRIVERS+=("mesa" "xf86-video-amdgpu" "vulkan-radeon"); fi
if echo "$VGA_DATA" | grep -q "nvidia"; then HAS_NVIDIA=1; DRIVERS+=("nvidia-open" "nvidia-utils" "nvidia-settings"); fi

TOTAL_GPUS=$((HAS_INTEL + HAS_AMD + HAS_NVIDIA))

if [ ${#DRIVERS[@]} -eq 0 ]; then
    echo "No specific hardware match found (or running in standard VM). Staging generic drivers..."
    DRIVERS+=("mesa")
fi

echo "Installing identified hardware drivers from local media cache: ${DRIVERS[*]}"
pacman -S --noconfirm "${DRIVERS[@]}"

if [ "$TOTAL_GPUS" -gt 1 ]; then
    echo "Dual-GPU array detected! Configuring hybrid profile management..."
    pacman -S --noconfirm switcheroo-control
    systemctl enable switcheroo-control
fi
