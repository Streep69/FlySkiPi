#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_samba.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Installing Samba Share..."

apt-get update -qq
apt-get install -y samba

mkdir -p /srv/fortressshare
chown nobody:nogroup /srv/fortressshare
chmod 777 /srv/fortressshare

cat >>/etc/samba/smb.conf <<'CONF'

[fortressshare]
   path = /srv/fortressshare
   browseable = yes
   read only = no
   guest ok = yes
CONF

systemctl restart smbd
ufw allow 'Samba'

echo "[✔] Samba share available on network as \\<ip>\fortressshare"
