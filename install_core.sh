#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_core_install.log
exec > >(tee -a "$LOG") 2>&1
echo "[*] Installing GPT-4Free Enhanced Stack"

# Install system dependencies
apt-get update -qq
apt-get install -y docker.io docker-compose-plugin git curl dos2unix

# Enable Docker
systemctl enable --now docker

# Clone or update GPT-4Free
if [[ ! -d /home/pi/gpt4free ]]; then
  git clone --depth=1 https://github.com/xtekky/gpt4free.git /home/pi/gpt4free
fi

cd /home/pi/gpt4free
[[ -f .env ]] || cp .env.template .env || true

# Build Docker image
docker build -t g4f:local .

# Docker Compose file using "g4f" container name to match original status script
cat >docker-compose.yml <<'YML'
version: "3.8"
services:
  gpt4free:
    image: g4f:local
    container_name: g4f
    restart: unless-stopped
    ports:
      - "1337:1337"
      - "8080:8080"
      - "7900:7900"
YML

# Start container
docker compose up -d

# Create status script with original structure
cat >/usr/local/bin/gpt4free_status.sh <<'EOF'
#!/bin/bash
echo "[*] GPT4Free Status Panel"
docker ps | grep g4f && echo "✓ Container is running" || echo "✗ Container is not running"
echo "[*] Accessible on:"
echo " - Chat: http://<your-ip>:1337/chat/"
echo " - Webmin: https://<your-ip>:10000"
EOF

chmod +x /usr/local/bin/gpt4free_status.sh

echo "[✔] GPT-4Free Enhanced Stack (structure-aligned) is running."
