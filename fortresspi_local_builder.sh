#!/bin/bash
set -e

echo "[*] FortressPi Local Builder & Publisher"

# Step 1: Generate GPG Key (if needed)
if ! gpg --list-keys | grep -q "fortresspi"; then
  echo "[*] Creating new GPG key (fortresspi@example.com)..."
  gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 2048
Name-Real: FortressPi
Name-Email: fortresspi@example.com
Expire-Date: 0
%no-protection
%commit
EOF
fi

# Step 2: Export Public Key
echo "[*] Exporting GPG public key..."
gpg --armor --output fortresspi_pubkey.gpg --export fortresspi@example.com

# Step 3: Sign APT Release File
echo "[*] Signing APT Release file..."
cd fortresspi_apt_repo
gpg --clearsign -o dists/stable/Release.gpg dists/stable/Release
cd ..

# Step 4: Download AppImage Tool
if [ ! -f appimagetool-x86_64.AppImage ]; then
  echo "[*] Downloading AppImageTool..."
  wget -q https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage
  chmod +x appimagetool-x86_64.AppImage
fi

# Step 5: Build AppImage
echo "[*] Building AppImage..."
unzip -o fortresspi-usbflasher-AppImageKit.zip -d fortresspi-usbflasher.AppDir
./appimagetool-x86_64.AppImage fortresspi-usbflasher.AppDir

echo "[✔] All done. AppImage and signed APT repo ready."
