#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "      WIRELESS NETWORK CONFIGURATOR      "
echo "========================================="

# 1. Discover active wireless radio hardware adapters
echo "Scanning for wireless network interfaces..."
WLAN_INTERFACE=$(iwctl device list | awk '/station/ {print $2}' | head -n 1 | xargs)

if [ -z "$WLAN_INTERFACE" ]; then
    echo "❌ Error: No wireless hardware adapter detected on physical system buses."
    exit 1
fi

echo "Found active wireless device interface: $WLAN_INTERFACE"

# 2. Trigger active radio sweeps to discover nearby access points
echo "Scanning local radio waves for available networks..."
iwctl station "$WLAN_INTERFACE" scan
sleep 2 # Provide the radio layer a brief moment to cache network frames

echo ""
echo "--- AVAILABLE NETWORKS (SSIDs) ---"
# Display clean, uncorrupted network list using native iwctl formatting
iwctl station "$WLAN_INTERFACE" get-networks
echo "----------------------------------"
echo ""

# 3. Solicit Target Network Identifiers from User
read -p "Enter the exact name (SSID) of the network you want to join: " CHOSEN_SSID

if [ -z "$CHOSEN_SSID" ]; then
    echo "❌ Error: SSID target string cannot be empty."
    exit 1
fi

read -s -p "Enter pre-shared security key (Password) for [$CHOSEN_SSID]: " SSID_PASSWORD
echo ""

# 4. Attempt Authentication handshake
echo "Initiating authentication connection sequence with $CHOSEN_SSID..."

# Pass the secret keys securely into the backend system shell process daemon
export IWD_PASSPHRASE="$SSID_PASSWORD"
if ! iwctl --passphrase "$IWD_PASSPHRASE" station "$WLAN_INTERFACE" connect "$CHOSEN_SSID"; then
    echo "❌ Error: Initial authentication dispatch failed. Validate credentials."
    exit 1
fi

# 5. Handshake Verification and Loop Check
echo "Waiting for DHCP and routing states to synchronize..."
CONNECTED=false

for i in {1..10}; do
    echo -n "."
    sleep 1.5
    # Confirm real layer-3 IP tracking states by hitting a public nameserver
    if ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        CONNECTED=true
        break
    fi
done
echo ""

if [ "$CONNECTED" = true ]; then
    echo "==============="
    echo "✅ SUCCESS: Internet connection fully verified!"
    echo "==============="
    sleep 1
else
    echo "❌ Error: Timed out waiting for network gateway confirmation."
    echo "Authentication might have passed, but DHCP failed to assign an IP address."
    exit 1
fi
