
#!/bin/bash

echo "[*] FortressPi Deployment Script Starting..."

# Ensure Python and Flask
sudo apt update
sudo apt install -y python3 python3-pip
pip3 install flask

# Run the Flask app
nohup python3 app.py > fortresspi.log 2>&1 &

echo "[+] FortressPi Web App running in background"

# If Fly.io CLI installed, deploy
if command -v flyctl &> /dev/null; then
  echo "[*] Deploying to Fly.io"
  flyctl deploy
else
  echo "[!] Fly.io CLI not found. Run 'curl -L https://fly.io/install.sh | sh' to install it."
fi
