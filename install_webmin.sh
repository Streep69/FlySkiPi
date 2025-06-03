#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_webmin_install.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Installing Webmin..."
apt-get update -qq
apt-get install -y software-properties-common apt-transport-https wget gnupg ufw

# Use modern method to import Webmin key
wget -qO- http://www.webmin.com/jcameron-key.asc | gpg --dearmor -o /usr/share/keyrings/webmin.gpg
echo "deb [signed-by=/usr/share/keyrings/webmin.gpg] http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list

apt-get update -qq
apt-get install -y webmin
systemctl enable --now webmin

# Open firewall port
ufw allow 10000

echo "[✔] Webmin installed and accessible at https://<your-ip>:10000"
