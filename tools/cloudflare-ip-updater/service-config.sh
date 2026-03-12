#!/usr/bin/env bash

set -e

SCRIPT_SOURCE="./cloudflare-update-ip.sh"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="cloudflare-update-ip.sh"
CONFIG_FILE="/etc/cloudflare-ddns.conf"

echo "Cloudflare DDNS Installer"
echo "-------------------------"

# Verify updater script exists
if [ ! -f "$SCRIPT_SOURCE" ]; then
    echo "Error: $SCRIPT_SOURCE not found in current directory."
    exit 1
fi

# Check dependencies
echo "Checking dependencies..."

if ! command -v curl >/dev/null; then
    echo "Installing curl..."
    sudo apt install -y curl
fi

if ! command -v jq >/dev/null; then
    echo "Installing jq..."
    sudo apt install -y jq
fi

echo

# Ask configuration
read -p "Cloudflare API Token: " API_TOKEN
read -p "Zone ID: " ZONE_ID
read -p "Record ID: " RECORD_ID
read -p "Full domain (example: home.example.com): " DOMAIN

echo

# Create config file
echo "Creating configuration file..."
echo "Requesting sudo permissions to write to /etc and configure strict root permissions."

sudo tee "$CONFIG_FILE" >/dev/null <<EOF
API_TOKEN="$API_TOKEN"
ZONE_ID="$ZONE_ID"
RECORD_ID="$RECORD_ID"
DOMAIN="$DOMAIN"
EOF

sudo chmod 600 "$CONFIG_FILE"
sudo chown $UID "$CONFIG_FILE"

# Install update script
echo "Installing updater script..."

sudo cp "$SCRIPT_SOURCE" "$INSTALL_DIR/$SCRIPT_NAME"
sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo
echo "Choose execution method:"
echo "1) Cron job (runs every 5 minutes)"
echo "2) NetworkManager dispatcher (runs on network change)"
echo

read -p "Select option [1-2]: " OPTION

if [ "$OPTION" = "1" ]; then

    echo "Installing cron job..."

    (crontab -l 2>/dev/null; echo "*/5 * * * * $INSTALL_DIR/$SCRIPT_NAME") | crontab -

    echo "Cron job installed."

elif [ "$OPTION" = "2" ]; then

    DISPATCHER="/etc/NetworkManager/dispatcher.d/99-cloudflare-ddns"

    echo "Installing NetworkManager dispatcher..."

    sudo tee "$DISPATCHER" >/dev/null <<EOF
#!/usr/bin/env bash
$INSTALL_DIR/$SCRIPT_NAME
EOF

    sudo chmod +x "$DISPATCHER"

    echo "Dispatcher installed."

else
    echo "Invalid option."
    exit 1
fi

echo
echo "Installation complete."
echo
echo "Test with:"
echo "$INSTALL_DIR/$SCRIPT_NAME"