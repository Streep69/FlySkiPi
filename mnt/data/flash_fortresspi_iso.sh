#!/bin/bash
set -euo pipefail

ISO="FortressPi_Live.iso"
DEVICE="$1"

if [ -z "$DEVICE" ]; then
  echo "Usage: sudo ./flash_fortresspi_iso.sh /dev/sdX"
  echo "WARNING: This will erase all data on the target drive!"
  exit 1
fi

if [ ! -f "$ISO" ]; then
  echo "ISO file '$ISO' not found in current directory."
  exit 1
fi

echo "[*] Flashing $ISO to $DEVICE..."
echo "THIS WILL ERASE ALL DATA ON $DEVICE!"
read -p "Type YES to continue: " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

sudo dd if="$ISO" of="$DEVICE" bs=4M status=progress oflag=sync
echo "[✔] Flash complete. You can now boot from $DEVICE."
