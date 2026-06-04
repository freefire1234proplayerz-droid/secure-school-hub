#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/secure-school-hub"
DOMAIN="${1:-example.com}"
EMAIL="${2:-admin@example.com}"

echo "== SecureSchoolHub Ubuntu setup =="
echo "App directory: ${APP_DIR}"
echo "Domain: ${DOMAIN}"

sudo apt-get update
sudo apt-get install -y ufw docker.io docker-compose-plugin certbot python3-certbot-nginx wireguard qrencode

sudo systemctl enable docker
sudo systemctl start docker

echo "Configuring UFW..."
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "Setting up WireGuard (basic)..."
if [ ! -f /etc/wireguard/wg0.conf ]; then
  sudo umask 077
  sudo wg genkey | tee /etc/wireguard/server_private.key | wg pubkey | tee /etc/wireguard/server_public.key
  SERVER_PRIV_KEY=$(sudo cat /etc/wireguard/server_private.key)
  sudo bash -c "cat >/etc/wireguard/wg0.conf" <<EOF
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = ${SERVER_PRIV_KEY}
SaveConfig = true

# Add peer configs manually for each school admin device.
EOF
  sudo systemctl enable wg-quick@wg0
  sudo systemctl start wg-quick@wg0
  sudo ufw allow 51820/udp
fi

echo "Cloning or updating app repo..."
sudo mkdir -p "${APP_DIR}"
sudo chown "$USER":"$USER" "${APP_DIR}"

if [ ! -d "${APP_DIR}/.git" ]; then
  echo "Copy your project files into ${APP_DIR} (or git clone) and then run this script again."
fi

echo "Running docker-compose..."
cd "${APP_DIR}"
sudo docker compose pull || true
sudo docker compose up -d --build

echo "Configuring Nginx with Certbot..."
if ! command -v nginx >/dev/null 2>&1; then
  sudo apt-get install -y nginx
fi

sudo tee /etc/nginx/sites-available/secure-school-hub.conf >/dev/null <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/secure-school-hub.conf /etc/nginx/sites-enabled/secure-school-hub.conf
sudo nginx -t
sudo systemctl reload nginx

sudo certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" || {
  echo "Certbot failed; ensure DNS is pointing to this server."
}

echo "Setup complete. Backend should be available via https://${DOMAIN}"

