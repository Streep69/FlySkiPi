#!/bin/bash

ZIP_FILE="$1"
REQUIRED_FILES=(
  "app.py"
  "FORTRESSPI_DOCUMENTATION.pdf"
  "bloody.css"
  "moonlight.css"
  "theme_switcher.js"
  "gpt4free_enhancer.sh"
  "validator_core.sh"
  "install_backup.sh"
  "backup_restore.sh"
  "install_watchdog.sh"
  "install_upload_panel.sh"
  "install_webhook.sh"
  "install_copilot_webhook.sh"
  "install_reverseproxy.sh"
  "install_reverseproxy_ssl.sh"
  "install_webmin.sh"
  "install_monitoring.sh"
  "install_samba.sh"
  "install_samba_sync.sh"
  "flash_fortresspi_iso.sh"
)

if [ -z "$ZIP_FILE" ]; then
  echo "Usage: ./validate_fortresspi_zip.sh <zip-file>"
  exit 1
fi

echo "📦 Validating FortressPi package: $ZIP_FILE"
TEMP_DIR=$(mktemp -d)

unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

MISSING=0
for FILE in "${REQUIRED_FILES[@]}"; do
  if [ ! -s "$TEMP_DIR/$FILE" ]; then
    echo "❌ Missing or empty: $FILE"
    MISSING=1
  else
    echo "✅ $FILE present and non-empty"
  fi
done

if [ "$MISSING" -eq 0 ]; then
  echo "✅ All required files are present and contain logic"
else
  echo "⚠️ One or more files are missing or appear to be stubs"
fi

rm -rf "$TEMP_DIR"
