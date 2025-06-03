#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_watchdog.log
exec > >(tee -a "$LOG") 2>&1

# Create watchdog logic
cat >/usr/local/bin/fortresspi_watchdog.sh <<'EOF'
#!/bin/bash
SERVICES=("upload-panel-cli.service")
CONTAINERS=("g4f")

for s in "${SERVICES[@]}"; do
    if ! systemctl is-active --quiet "$s"; then
        echo "✗ $s was not running. Restarting..."
        systemctl restart "$s"
    else
        echo "✓ $s is active"
    fi
done

for c in "${CONTAINERS[@]}"; do
    if ! docker ps | grep -q "$c"; then
        echo "✗ Container $c not running. Attempting restart via docker-compose..."
        if [[ -d /home/pi/gpt4free ]]; then
            cd /home/pi/gpt4free
            docker compose up -d || echo "✗ Failed to restart $c with docker compose"
        else
            echo "✗ Directory /home/pi/gpt4free not found, cannot restart $c"
        fi
    else
        echo "✓ Container $c is running"
    fi
done

EOF

chmod +x /usr/local/bin/fortresspi_watchdog.sh

# Timer + service
cat >/etc/systemd/system/fortresspi_watcher.service <<'UNIT'
[Unit]
Description=FortressPi Watchdog
After=network.target

[Service]
ExecStart=/usr/local/bin/fortresspi_watchdog.sh
Type=oneshot
UNIT

cat >/etc/systemd/system/fortresspi_watcher.timer <<'UNIT'
[Unit]
Description=Run FortressPi Watchdog every 5 min

[Timer]
OnBootSec=1min
OnUnitInactiveSec=5min
Unit=fortresspi_watcher.service

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now fortresspi_watcher.timer

echo "[✔] FortressPi Watchdog timer activated"
