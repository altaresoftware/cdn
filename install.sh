#!/usr/bin/env bash
set -e

# COLORS
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

echo -e "${GREEN}──────────────────────────────────────────────${RESET}"
echo -e "${GREEN}Install Cryogenic Daemon${RESET}"
echo -e "${GREEN}──────────────────────────────────────────────${RESET}"

read -p "Node Name (e.g. nl-ams02): " NODE_NAME
NODE_FQDN="${NODE_NAME}.altr.cc"
EMAIL="info@altare.cv"

echo -e "${YELLOW}Ok, one moment...${RESET}"

# Quiet everything except Cryogenic line
exec 3>&1
exec >/dev/null 2>&1

ufw disable || true
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
mkdir -p /etc/pterodactyl

# Only visible output:
exec 1>&3 2>&3
echo -e "${YELLOW}Installing Cryogenic...${RESET}"
exec >/dev/null 2>&1

curl -sSL "https://github.com/altaresoftware/cdn/raw/refs/heads/main/cryogenic" \
    -o /usr/local/bin/cryogenic
chmod +x /usr/local/bin/cryogenic

exec 1>&3 2>&3
echo -e "${YELLOW}Installing Cryogenic...done${RESET}"
exec >/dev/null 2>&1

apt update
apt install -y certbot

certbot certonly --standalone -d "$NODE_FQDN" \
    --non-interactive --agree-tos -m "$EMAIL"

docker network create --driver bridge pterodactyl_nw || true

cat <<'EOF' > /etc/systemd/system/cryogenic.service
[Unit]
Description=Cryogenic Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/cryogenic
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cryogenic.service

exec 1>&3 2>&3
echo -e "${GREEN}Done. Node: ${NODE_FQDN}${RESET}"
