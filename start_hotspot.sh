#!/bin/bash
set -e

# === Configuration ===
HOTSPOT_IF="wlan1"
INTERNET_IF="wlan0"
SSID="TestHotspot"
PASSWORD="12345678"
HOTSPOT_IP="192.168.4.1"
DHCP_RANGE_START="192.168.4.10"
DHCP_RANGE_END="192.168.4.50"
CHANNEL="7"

echo "🛑 Arrêt de dnsmasq et hostapd (s'ils tournent déjà)..."
sudo systemctl stop dnsmasq || true
sudo systemctl stop hostapd || true

echo "📡 Mise en UP de l'interface $HOTSPOT_IF..."
sudo ip link set "$HOTSPOT_IF" up
sudo ip addr flush dev "$HOTSPOT_IF"
sudo ip addr add "$HOTSPOT_IP/24" dev "$HOTSPOT_IF"

echo "🧠 Écriture du fichier de config hostapd..."
sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
interface=$HOTSPOT_IF
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" | sudo tee /etc/default/hostapd

echo "🚧 Configuration du serveur DHCP via dnsmasq..."
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
interface=$HOTSPOT_IF
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
EOF

echo "🌍 Activation du routage IPv4..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null

echo "🔥 Configuration NAT entre $HOTSPOT_IF et $INTERNET_IF..."
sudo iptables -t nat -A POSTROUTING -o "$INTERNET_IF" -j MASQUERADE
sudo iptables -A FORWARD -i "$INTERNET_IF" -o "$HOTSPOT_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i "$HOTSPOT_IF" -o "$INTERNET_IF" -j ACCEPT

echo "✅ Lancement de dnsmasq et hostapd..."
sudo systemctl start dnsmasq
sudo systemctl start hostapd

echo "✅ Hotspot lancé !"
echo "➡️  SSID : $SSID"
echo "➡️  Mot de passe : $PASSWORD"
