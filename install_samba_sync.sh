#!/usr/bin/env bash
set -e
apt-get update -qq
apt-get install -y samba
mkdir -p /srv/fortressshare
cat >>/etc/samba/smb.conf <<'SMB'
[FortressShare]
   path = /srv/fortressshare
   read only = no
   guest ok = yes
SMB
systemctl restart smbd
cat >/usr/local/bin/auto_sync_to_samba.sh <<'SH'
#!/usr/bin/env bash
rsync -a --delete /mnt/fortressshare/uploads/ /srv/fortressshare/uploads/
SH
chmod +x /usr/local/bin/auto_sync_to_samba.sh
cat >/etc/systemd/system/auto-sync-samba.service <<'UNIT'
[Unit] Description=Sync uploads to Samba share
[Service] ExecStart=/usr/local/bin/auto_sync_to_samba.sh
[Install] WantedBy=multi-user.target
UNIT
cat >/etc/systemd/system/auto-sync-samba.timer <<'UNIT'
[Unit] Description=Sync uploads every 10min
[Timer] OnBootSec=2min OnUnitInactiveSec=10min
[Install] WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now auto-sync-samba.timer
echo "Samba share available and sync timer started"
