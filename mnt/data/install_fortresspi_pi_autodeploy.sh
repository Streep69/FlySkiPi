#!/bin/bash
echo "🛡️ FortressPi Auto-Setup Starting..."

# Step 1: Ensure required packages
echo "📦 Installing system dependencies..."
sudo apt update && sudo apt install -y unzip python3 python3-pip curl

# Step 2: Unzip the integrated archive
echo "🗂️ Extracting FortressPi..."
unzip FortressPi_v22_Integrated_FULL.zip -d fortresspi_app
cd fortresspi_app || exit 1

# Step 3: Install Python dependencies
echo "🐍 Installing Python packages..."
pip3 install flask

# Step 4: Start app in background
echo "🚀 Starting FortressPi Web App..."
nohup python3 app.py > fortresspi.log 2>&1 &

# Step 5: Check if flyctl is installed
if command -v flyctl &> /dev/null; then
  echo "🌍 Fly.io CLI found — deploying..."
  flyctl deploy
else
  echo "⚠️  Fly.io CLI not installed. To deploy manually, run:"
  echo "  curl -L https://fly.io/install.sh | sh"
fi

echo "✅ Setup complete. Visit http://<pi-ip>:5000 in your browser."
