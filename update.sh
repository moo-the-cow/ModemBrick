#!/usr/bin/env bash
# Usage: sudo ./update.sh <URL_TO_TAR_GZ>
set -e

DOWNLOAD_URL="$1"
TARGET_DIR="/opt/ModemBrick"
TEMP_FILE="/tmp/ModemBrick_update.tar.gz"

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: No download URL provided."
    exit 1
fi

echo "==> Stopping modembrick.service..."
systemctl stop modembrick.service || true

echo "==> Downloading application payload..."
curl -sSL -o "$TEMP_FILE" "$DOWNLOAD_URL"

echo "==> Deploying code to $TARGET_DIR..."
# Ensure directory exists and clean old files if necessary, or just extract over them
mkdir -p "$TARGET_DIR"
tar -xzf "$TEMP_FILE" -C "$TARGET_DIR" --overwrite

echo "==> Cleaning up artifacts..."
rm -f "$TEMP_FILE"

echo "==> Correcting folder ownership..."
if id "dietpi" &>/dev/null; then
  chown -R dietpi:dietpi /opt
fi

echo "==> Starting modembrick.service..."
systemctl start modembrick.service

echo "==> Update complete!"