#!/usr/bin/env bash

LOG_TAG="cloudflare-ddns"

log() {
    logger -t "$LOG_TAG" "$1"
}

CONFIG="/etc/cloudflare-ddns.conf"
source "$CONFIG"

# Get public IP from ipify
CURRENT_IP=$(curl -s https://api.ipify.org)

# Get current DNS record IP
DNS_IP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $API_TOKEN" \
     -H "Content-Type: application/json" | jq -r '.result.content')

log "Public IP: $CURRENT_IP"
log "DNS IP:    $DNS_IP"

if [ "$CURRENT_IP" = "$DNS_IP" ]; then
    log "IP unchanged. No update needed."
    exit 0
fi

log "Updating Cloudflare DNS..."

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $API_TOKEN" \
     -H "Content-Type: application/json" \
     --data "{
        \"type\":\"A\",
        \"name\":\"$DOMAIN\",
        \"content\":\"$CURRENT_IP\",
        \"ttl\":120,
        \"proxied\":false
     }"

log "DNS record updated to $CURRENT_IP"

