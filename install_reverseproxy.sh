#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_reverseproxy.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Setting up HTTPS reverse proxy with mkcert..."

apt-get update -qq
apt-get install -y nginx libnss3-tools mkcert ufw

mkdir -p /etc/nginx/ssl
cd /etc/nginx/ssl
mkcert -install
mkcert localhost

# Redirect HTTP to HTTPS
cat >/etc/nginx/sites-available/redirect_http <<'REDIRECT'
server {
    listen 80;
    server_name localhost;
    return 301 https://$host$request_uri;
}
REDIRECT

# HTTPS Proxy for GPT-4Free /chat
cat >/etc/nginx/sites-available/reverse_proxy <<'NG'
server {
  listen 443 ssl;
  server_name localhost;

  ssl_certificate /etc/nginx/ssl/localhost.pem;
  ssl_certificate_key /etc/nginx/ssl/localhost-key.pem;

  location /chat/ {
    proxy_pass http://localhost:1337/chat/;
    proxy_set_header Host $host;
  }
}
NG

ln -sf /etc/nginx/sites-available/redirect_http /etc/nginx/sites-enabled/redirect_http
ln -sf /etc/nginx/sites-available/reverse_proxy /etc/nginx/sites-enabled/reverse_proxy

systemctl restart nginx
ufw allow 443
ufw allow 80

echo "[✔] HTTPS reverse proxy configured with HTTP redirection"
