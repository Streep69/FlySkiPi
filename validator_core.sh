#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/gpt4free_validator.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Starting GPT-4Free validation: $(date)"

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    echo "✗ Docker is not installed"
    exit 1
fi

# Check if container is running
if ! docker ps | grep -q g4f; then
    echo "✗ GPT-4Free container 'g4f' is not running"
    exit 1
else
    echo "✓ Container 'g4f' is running"
fi

# Check API availability
URL="http://localhost:1337/v1/models"
HTTP_STATUS=$(curl -s -o /tmp/gpt4free_response.json -w "%{http_code}" "$URL" || true)

if [[ "$HTTP_STATUS" -eq 200 ]]; then
    echo "✓ GPT-4Free API responded with HTTP 200"
    echo "[*] Response preview:"
    head -n 10 /tmp/gpt4free_response.json
else
    echo "✗ API call to $URL failed with HTTP status $HTTP_STATUS"
    if [[ -s /tmp/gpt4free_response.json ]]; then
        echo "[!] Partial response content:"
        cat /tmp/gpt4free_response.json
    else
        echo "[!] No response body received."
    fi
    exit 1
fi

echo "[✔] GPT-4Free validation completed successfully."
