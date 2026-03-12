#!/usr/bin/env bash

set -e

INSTALL_SCRIPT="/usr/local/bin/cloudflare-update-ip.sh"

echo "Cloudflare DDNS Uninstaller"
echo "---------------------------"
echo

read -p "Enter path of config file in /etc (example: /etc/cloudflare-ddns.conf): " CONFIG_FILE

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found."
    exit 1
fi

# Load config
source "$CONFIG_FILE"

echo "Detected installation method: $INSTALL_METHOD"
echo

# Remove integration based on method
if [ "$INSTALL_METHOD" = "cron" ]; then

    echo "Removing cron job..."

    CRON_TMP=$(mktemp)

    crontab -l 2>/dev/null | grep -v "$INSTALL_SCRIPT" > "$CRON_TMP" || true
    crontab "$CRON_TMP" 2>/dev/null || true

    rm -f "$CRON_TMP"

    echo "Cron job removed."

elif [ "$INSTALL_METHOD" = "networkmanager" ]; then

    DISPATCHER="/etc/NetworkManager/dispatcher.d/99-cloudflare-ddns"

    if [ -f "$DISPATCHER" ]; then
        echo "Removing NetworkManager dispatcher script..."
        sudo rm -f "$DISPATCHER"
    fi

else
    echo "Unknown or missing INSTALL_METHOD in config."
    echo "Skipping integration removal."
fi

# Remove installed updater script
if [ -f "$INSTALL_SCRIPT" ]; then
    echo "Removing updater script..."
    sudo rm -f "$INSTALL_SCRIPT"
fi

echo
read -p "Remove config file ($CONFIG_FILE)? [y/N]: " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    sudo rm -f "$CONFIG_FILE"
    echo "Config file removed."
fi

echo
echo "Uninstallation complete."