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

sudo apt update
sudo apt install -y hostapd dnsmasq

echo "📡 Détection du canal Wi-Fi utilisé par $INTERNET_IF..."
FREQ=$(iw dev $INTERNET_IF link | grep freq | awk '{print $2}')
CHANNEL=""
case "$FREQ" in
  2412) CHANNEL=1 ;;
  2417) CHANNEL=2 ;;
  2422) CHANNEL=3 ;;
  2427) CHANNEL=4 ;;
  2432) CHANNEL=5 ;;
  2437) CHANNEL=6 ;;
  2442) CHANNEL=7 ;;
  2447) CHANNEL=8 ;;
  2452) CHANNEL=9 ;;
  2457) CHANNEL=10 ;;
  2462) CHANNEL=11 ;;
  2467) CHANNEL=12 ;;
  2472) CHANNEL=13 ;;
  *) echo "⚠️ Fréquence inconnue ($FREQ). Canal par défaut : 6" ; CHANNEL=6 ;;
esac
echo "✅ Canal détecté : $CHANNEL"

echo "🔁 Suppression de l’interface $HOTSPOT_IF (si elle existe déjà)..."
sudo iw dev $HOTSPOT_IF del 2>/dev/null || true

echo "➕ Création de l’interface $HOTSPOT_IF en mode AP..."
sudo iw dev $INTERNET_IF interface add $HOTSPOT_IF type __ap

echo "🔌 Mise en UP + attribution IP statique..."
sudo ip link set $HOTSPOT_IF up
sudo ip addr flush dev $HOTSPOT_IF
sudo ip addr add $HOTSPOT_IP/24 dev $HOTSPOT_IF

echo "🧠 Génération de /etc/hostapd/hostapd.conf..."
sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
interface=$HOTSPOT_IF
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
ieee80211n=1
EOF

echo "🚧 Configuration de dnsmasq..."
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
interface=$HOTSPOT_IF
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
EOF

echo "🌍 Activation du routage IP + NAT..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo iptables -t nat -A POSTROUTING -o $INTERNET_IF -j MASQUERADE
sudo iptables -A FORWARD -i $INTERNET_IF -o $HOTSPOT_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $HOTSPOT_IF -o $INTERNET_IF -j ACCEPT

echo "✅ Lancement de dnsmasq..."
sudo systemctl restart dnsmasq

echo "🚀 Lancement de hostapd en ligne de commande..."
sudo hostapd /etc/hostapd/hostapd.conf
