#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_monitoring_install.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Installing Prometheus Node Exporter..."
apt-get update -qq
apt-get install -y prometheus-node-exporter ufw

systemctl enable --now prometheus-node-exporter

# Open monitoring port
ufw allow 9100

# Health check
curl -s http://localhost:9100/metrics | head -n 5 || { echo "✗ Node Exporter not responding"; exit 1; }

echo "[✔] Node Exporter running and available on port 9100"
