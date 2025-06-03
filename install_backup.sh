#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_backup.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Installing FortressPi Backup Utility..."

apt-get update -qq
apt-get install -y rsync

BACKUP_DIR="/mnt/fortressshare/backups"
SOURCE_DIR="/mnt/fortressshare/uploads"

mkdir -p "$BACKUP_DIR"

cat >/usr/local/bin/fortresspi_backup.sh <<'EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SRC="/mnt/fortressshare/uploads"
DEST="/mnt/fortressshare/backups/backup_$TIMESTAMP"
mkdir -p "$DEST"
rsync -av "$SRC/" "$DEST/"
echo "Backup completed at $DEST"
EOF

chmod +x /usr/local/bin/fortresspi_backup.sh

cat >/etc/systemd/system/fortresspi_backup.timer <<'UNIT'
[Unit]
Description=Scheduled FortressPi Backup

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
UNIT

cat >/etc/systemd/system/fortresspi_backup.service <<'UNIT'
[Unit]
Description=FortressPi Backup Task

[Service]
ExecStart=/usr/local/bin/fortresspi_backup.sh
UNIT

systemctl daemon-reload
systemctl enable --now fortresspi_backup.timer

echo "[✔] Backup system installed. Files backed up hourly."
