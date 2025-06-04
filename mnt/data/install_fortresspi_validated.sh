#!/bin/bash

echo "🔧 FortressPi Auto Installer – Validated"

TARGET_DIR="/mnt/fortressshare/fortresspi"

if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ Target not found: $TARGET_DIR"
  echo "Ensure the SAMBA share is mounted at /mnt/fortressshare/"
  exit 1
fi

# Check app.py exists
if [ ! -f "$TARGET_DIR/app.py" ]; then
  echo "❌ Missing app.py in $TARGET_DIR"
  exit 2
fi

# Install Flask if not present
if ! python3 -c "import flask" 2>/dev/null; then
  echo "📦 Installing Flask..."
  pip3 install flask
fi

# Set up systemd service
echo "🛠️ Installing systemd service..."
sudo cp fortresspi.service /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl enable fortresspi.service
sudo systemctl restart fortresspi.service

echo "✅ FortressPi deployed and running."
echo "🌍 Access: http://<your-pi-ip>:5000"
