#!/bin/bash
set -e

if ! command -v zenity >/dev/null; then
  echo "Zenity not installed. Run: sudo apt install zenity"
  exit 1
fi

ISO="FortressPi_Live.iso"

if [ ! -f "$ISO" ]; then
  zenity --error --text="ISO file '$ISO' not found in current directory."
  exit 1
fi

DEVICES=$(lsblk -dpno NAME,SIZE,MODEL | grep -v "loop\|sr0")
DEVICE=$(echo "$DEVICES" | zenity --list --title="Select USB Device" --column="Device" --column="Size/Model" --height=300 --width=500)

if [ -z "$DEVICE" ]; then
  zenity --warning --text="No device selected. Aborting."
  exit 1
fi

zenity --question --text="This will erase ALL data on $DEVICE. Proceed?" || exit 1

(
  echo "10"
  echo "# Flashing ISO to $DEVICE..."
  sudo dd if="$ISO" of="$DEVICE" bs=4M status=progress oflag=sync
  echo "100"
  echo "# Flash complete!"
) | zenity --progress --title="Writing ISO" --percentage=0 --auto-close

zenity --info --text="FortressPi ISO successfully written to $DEVICE. You can now boot from USB."
