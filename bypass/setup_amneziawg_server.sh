#!/bin/bash
# ============================================================
#  AmneziaWG Server Setup for HoN RU Pack
#  Run on VPS (Ubuntu 20.04/22.04/24.04) as root
# ============================================================
set -e

echo "============================================"
echo "  AmneziaWG Server Setup for HoN RU Pack"
echo "============================================"

# Detect OS
. /etc/os-release
echo "[+] OS: $PRETTY_NAME"
echo "[+] Kernel: $(uname -r)"

# ---- Step 1: Stop and remove existing WireGuard if present ----
echo ""
echo "[1/7] Removing existing WireGuard (if any)..."
if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
    systemctl stop wg-quick@wg0
    systemctl disable wg-quick@wg0 2>/dev/null || true
    echo "  Stopped wg-quick@wg0"
fi
if command -v wg &>/dev/null; then
    apt-get remove -y wireguard wireguard-tools 2>/dev/null || true
    echo "  Removed standard WireGuard"
fi

# ---- Step 2: Install AmneziaWG ----
echo ""
echo "[2/7] Installing AmneziaWG..."

# Add AmneziaWG repository
apt-get update -qq
apt-get install -y software-properties-common curl gnupg2

# Install from AmneziaWG PPA / packages
# Method: build from source or use pre-built packages
# Using the official install script approach
apt-get install -y build-essential linux-headers-$(uname -r) git pkg-config

# Clone and build amneziawg-linux-kernel-module
cd /tmp
if [ -d "amneziawg-linux-kernel-module" ]; then
    rm -rf amneziawg-linux-kernel-module
fi
echo "  Cloning AmneziaWG kernel module..."
git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
cd amneziawg-linux-kernel-module/src
echo "  Building kernel module..."
make -j$(nproc)
make install
echo "  Kernel module installed"

# Clone and build amneziawg-tools
cd /tmp
if [ -d "amneziawg-tools" ]; then
    rm -rf amneziawg-tools
fi
echo "  Cloning AmneziaWG tools..."
git clone https://github.com/amnezia-vpn/amneziawg-tools.git
cd amneziawg-tools/src
make -j$(nproc)
make install
echo "  AmneziaWG tools installed"

# Load the module
modprobe amneziawg 2>/dev/null || depmod -a && modprobe amneziawg
echo "  Module loaded: $(lsmod | grep amneziawg | head -1)"

# ---- Step 3: Generate keys ----
echo ""
echo "[3/7] Generating keys..."

SERVER_PRIVKEY=$(awg genkey)
SERVER_PUBKEY=$(echo "$SERVER_PRIVKEY" | awg pubkey)

CLIENT_PRIVKEY=$(awg genkey)
CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | awg pubkey)

PRESHARED_KEY=$(awg genpsk)

echo "  Server public key: $SERVER_PUBKEY"
echo "  Client public key: $CLIENT_PUBKEY"

# ---- Step 4: Generate obfuscation parameters ----
echo ""
echo "[4/7] Setting obfuscation parameters..."

# AmneziaWG obfuscation parameters (Junk packets, init header transforms)
# Jc  = Junk packet count (number of junk packets in handshake, 1-128)
# Jmin = Junk packet minimum size (40-1280)
# Jmax = Junk packet maximum size (Jmin-1280)
# S1  = Init packet header magic byte 1 (1-255)
# S2  = Init packet header magic byte 2 (1-255)
# H1-H4 = Handshake header transform values (1-2147483647)
AWG_Jc=4
AWG_Jmin=50
AWG_Jmax=1000
AWG_S1=68
AWG_S2=84
AWG_H1=981756423
AWG_H2=725841693
AWG_H3=412685937
AWG_H4=158973264

echo "  Jc=$AWG_Jc Jmin=$AWG_Jmin Jmax=$AWG_Jmax"
echo "  S1=$AWG_S1 S2=$AWG_S2"
echo "  H1=$AWG_H1 H2=$AWG_H2 H3=$AWG_H3 H4=$AWG_H4"

# ---- Step 5: Detect main interface and create server config ----
echo ""
echo "[5/7] Creating server config..."

# Detect main network interface
MAIN_IF=$(ip route show default | awk '/default/ {print $5}' | head -1)
SERVER_IP=$(ip -4 addr show "$MAIN_IF" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)

echo "  Main interface: $MAIN_IF"
echo "  Server IP: $SERVER_IP"

mkdir -p /etc/amnezia/amneziawg

cat > /etc/amnezia/amneziawg/awg0.conf << EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVKEY
PostUp = iptables -A FORWARD -i awg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $MAIN_IF -j MASQUERADE
PostDown = iptables -D FORWARD -i awg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $MAIN_IF -j MASQUERADE
Jc = $AWG_Jc
Jmin = $AWG_Jmin
Jmax = $AWG_Jmax
S1 = $AWG_S1
S2 = $AWG_S2
H1 = $AWG_H1
H2 = $AWG_H2
H3 = $AWG_H3
H4 = $AWG_H4

[Peer]
# HoN RU Pack Client
PublicKey = $CLIENT_PUBKEY
PresharedKey = $PRESHARED_KEY
AllowedIPs = 10.66.66.2/32
EOF

chmod 600 /etc/amnezia/amneziawg/awg0.conf
echo "  Server config saved to /etc/amnezia/amneziawg/awg0.conf"

# ---- Step 6: Enable IP forwarding and start ----
echo ""
echo "[6/7] Enabling IP forwarding and starting AmneziaWG..."

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-amneziawg.conf
sysctl -w net.ipv4.ip_forward=1

# Disable strict reverse path filtering
echo "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.d/99-amneziawg.conf
echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.d/99-amneziawg.conf
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0

# Remove old WireGuard interface if exists
ip link del wg0 2>/dev/null || true

# Start AmneziaWG
awg-quick up /etc/amnezia/amneziawg/awg0.conf
echo "  AmneziaWG interface awg0 is UP"

# Enable at boot via systemd
cat > /etc/systemd/system/amneziawg@.service << 'SVCEOF'
[Unit]
Description=AmneziaWG Tunnel %i
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/awg-quick up /etc/amnezia/amneziawg/%i.conf
ExecStop=/usr/local/bin/awg-quick down /etc/amnezia/amneziawg/%i.conf

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable amneziawg@awg0
echo "  Enabled at boot: amneziawg@awg0"

# ---- Step 7: Generate client config ----
echo ""
echo "[7/7] Generating client config..."

CLIENT_CONFIG="[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = 10.66.66.2/32
DNS = 1.1.1.1
MTU = 1280
Jc = $AWG_Jc
Jmin = $AWG_Jmin
Jmax = $AWG_Jmax
S1 = $AWG_S1
S2 = $AWG_S2
H1 = $AWG_H1
H2 = $AWG_H2
H3 = $AWG_H3
H4 = $AWG_H4

[Peer]
PublicKey = $SERVER_PUBKEY
PresharedKey = $PRESHARED_KEY
Endpoint = ${SERVER_IP}:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25"

echo "$CLIENT_CONFIG" > /root/hon_ru_pack_client.conf
chmod 600 /root/hon_ru_pack_client.conf

echo ""
echo "============================================"
echo "  SETUP COMPLETE!"
echo "============================================"
echo ""
echo "Server status:"
awg show awg0
echo ""
echo "============================================"
echo "  CLIENT CONFIG (save this!):"
echo "============================================"
echo ""
echo "$CLIENT_CONFIG"
echo ""
echo "============================================"
echo "Config also saved to: /root/hon_ru_pack_client.conf"
echo "============================================"
