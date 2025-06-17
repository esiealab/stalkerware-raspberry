#!/bin/bash
set -e

WIFI_SSID="esiealab-ext"
WIFI_PASSWORD="esiealab2025"
IFACE="wlan0"

echo "🔌 Connexion au Wi-Fi $WIFI_SSID via $IFACE..."
nmcli device wifi rescan
nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASSWORD" ifname "$IFACE" name wifi_externe
echo "✅ Connecté à $WIFI_SSID"
