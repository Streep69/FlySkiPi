#!/usr/bin/env bash
set -e
apt-get update -qq
apt-get install -y nginx mkcert
mkcert -install
mkcert -key-file /etc/ssl/private/fortress.key -cert-file /etc/ssl/certs/fortress.crt "$(hostname)" localhost 127.0.0.1
cat >/etc/nginx/sites-available/gpt_ssl <<'NG'
server {
 listen 443 ssl;
 server_name _;
 ssl_certificate /etc/ssl/certs/fortress.crt;
 ssl_certificate_key /etc/ssl/private/fortress.key;
 location / {
   proxy_pass http://127.0.0.1:8080;
   proxy_set_header Host $host;
   proxy_set_header X-Real-IP $remote_addr;
 }
}
NG
ln -sf /etc/nginx/sites-available/gpt_ssl /etc/nginx/sites-enabled/gpt_ssl
systemctl restart nginx
echo "HTTPS reverse proxy active on port 443"
