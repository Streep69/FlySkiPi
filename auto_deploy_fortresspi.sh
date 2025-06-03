#!/usr/bin/env bash
set -euo pipefail
ZIP_NAME="FortressPi_AllinOne_Validated.zip"
DEST="/mnt/fortressshare"

echo "[*] Checking for ZIP at /tmp or current dir..."
if [ -f "./$ZIP_NAME" ]; then
  SRC="./$ZIP_NAME"
elif [ -f "/tmp/$ZIP_NAME" ]; then
  SRC="/tmp/$ZIP_NAME"
else
  echo "[!] ZIP not found. Please place it in /tmp or current dir."
  exit 1
fi

echo "[*] Extracting $ZIP_NAME to $DEST"
sudo mkdir -p "$DEST"
sudo unzip -o "$SRC" -d "$DEST"
cd "$DEST"

echo "[*] Launching deployment..."
sudo bash FortressPi_Deploy.sh
