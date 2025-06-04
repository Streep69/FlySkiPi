#!/bin/bash

echo "📦 Deploying FortressPi to /mnt/fortressshare/ ..."

TARGET_DIR="/mnt/fortressshare/fortresspi"

# Ensure mount is available
if [ ! -d "/mnt/fortressshare" ]; then
    echo "❌ Shared SAMBA drive not mounted at /mnt/fortressshare"
    exit 1
fi

# Prepare target directory
mkdir -p "$TARGET_DIR"

# Extract contents into SAMBA share
unzip -o FortressPi_v22_Integrated_FULL.zip -d "$TARGET_DIR"

# Optionally, install Flask if this is the Pi
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📥 Installing Flask..."
    pip3 install flask
fi

# Start app
echo "🚀 Launching FortressPi from SAMBA share..."
cd "$TARGET_DIR" || exit 1
nohup python3 app.py > fortresspi.log 2>&1 &

echo "✅ Deployed to /mnt/fortressshare/fortresspi"
echo "🔗 Access via: http://<your-pi-ip>:5000"
