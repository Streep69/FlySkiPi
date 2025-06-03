#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_upload_panel.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Installing dual upload panels with PHP 8.0..."

# Install specific PHP version
apt-get update -qq
apt-get install -y php8.0 php8.0-cli php8.0-fpm nginx

# Ensure correct ownership and permissions
mkdir -p /mnt/fortressshare/uploads
chown -R www-data:www-data /mnt/fortressshare/uploads
chmod 755 /mnt/fortressshare/uploads

# CLI panel on port 8081
mkdir -p /var/www/upload_cli
cat >/var/www/upload_cli/index.php <<'PHP'
<?php
if ($_FILES) {
    $target = '/mnt/fortressshare/uploads/' . basename($_FILES['file']['name']);
    move_uploaded_file($_FILES['file']['tmp_name'], $target);
    echo "Uploaded to: " . htmlspecialchars($target);
}
?>
<form method="post" enctype="multipart/form-data">
  <input type="file" name="file">
  <button>Upload</button>
</form>
PHP

cat >/etc/systemd/system/upload-panel-cli.service <<'UNIT'
[Unit]
Description=Upload Panel CLI
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/upload_cli
ExecStart=/usr/bin/php8.0 -S 0.0.0.0:8081
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now upload-panel-cli.service

# FPM panel on port 8082
mkdir -p /var/www/upload_fpm
cp /var/www/upload_cli/index.php /var/www/upload_fpm/

cat >/etc/nginx/sites-available/upload_panel_fpm <<'NG'
server {
  listen 8082;
  root /var/www/upload_fpm;
  index index.php;

  location / {
    try_files $uri $uri/ =404;
  }

  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.0-fpm.sock;
  }
}
NG

ln -sf /etc/nginx/sites-available/upload_panel_fpm /etc/nginx/sites-enabled/upload_panel_fpm
systemctl restart nginx

# Allow firewall ports
ufw allow 8081
ufw allow 8082

echo "[✔] Upload panels deployed: CLI on 8081, FPM on 8082"
