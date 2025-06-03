#!/bin/bash
echo "[*] GPT4Free Status Panel"
docker ps | grep g4f && echo "✓ Container is running" || echo "✗ Container is not running"
echo "[*] Accessible on:"
echo " - Chat: http://<your-ip>:1337/chat/"
echo " - Webmin: https://<your-ip>:10000"
