#!/usr/bin/env bash
set -e
ACTION=${1:-backup}
TARGET=/mnt/fortressshare/backup_$(date +%Y%m%d_%H%M%S).tar.gz
if [[ $ACTION == backup ]]; then
  tar czf "$TARGET" /home/pi/gpt4free /etc
  echo "Backup saved to $TARGET"
elif [[ $ACTION == restore && -f $2 ]]; then
  tar xzf "$2" -C /
  echo "Restore complete"
else
  echo "Usage: $0 [backup|restore <file>]"
fi
