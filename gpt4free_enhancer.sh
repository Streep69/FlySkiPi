#!/bin/bash

echo "[*] Starting GPT4Free enhancement patch..."

# Stop existing container
echo "[*] Stopping any running GPT4Free containers..."
docker stop $(docker ps -q --filter ancestor=hlohaus789/g4f) 2>/dev/null
docker rm $(docker ps -aq --filter ancestor=hlohaus789/g4f) 2>/dev/null

# Create needed folders
mkdir -p ${PWD}/har_and_cookies ${PWD}/generated_media
sudo chown -R 1000:1000 ${PWD}/har_and_cookies ${PWD}/generated_media

# Pull latest slim image
echo "[*] Pulling latest GPT4Free Docker slim image..."
docker pull hlohaus789/g4f:latest-slim

# Run the container with public LAN access
echo "[*] Running GPT4Free container with proper LAN exposure..."
docker run -d   -p 0.0.0.0:1337:1337   -v ${PWD}/har_and_cookies:/app/har_and_cookies   -v ${PWD}/generated_media:/app/generated_media   hlohaus789/g4f:latest-slim   /bin/sh -c 'rm -rf /app/g4f && pip install -U g4f[slim] && python -m g4f --debug'

# Setup UFW rule (optional)
if command -v ufw &>/dev/null; then
    echo "[*] Allowing port 1337 in UFW firewall..."
    sudo ufw allow 1337/tcp
fi

# Setup systemd service
echo "[*] Creating systemd service for GPT4Free auto-start..."
cat <<EOF | sudo tee /etc/systemd/system/gpt4free.service
[Unit]
Description=GPT4Free Docker Container
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm -p 1337:1337 -v ${PWD}/har_and_cookies:/app/har_and_cookies -v ${PWD}/generated_media:/app/generated_media hlohaus789/g4f:latest-slim /bin/sh -c 'rm -rf /app/g4f && pip install -U g4f[slim] && python -m g4f --debug'
ExecStop=/usr/bin/docker stop %n

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Enabling and starting the service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable gpt4free
sudo systemctl start gpt4free

echo "[+] GPT4Free enhancement complete. Access at: http://<your-PI-IP>:1337/chat"
