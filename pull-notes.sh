#!/usr/bin/env bash
set -euo pipefail

# Pull the latest encrypted archive from GitHub and decrypt it.
# Usage: ./pull-notes.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTES_DIR="$SCRIPT_DIR/notesServer_enc_dec"
ARCHIVE="$SCRIPT_DIR/notesServer_enc"

cd "$SCRIPT_DIR"
git pull

if [[ -d "$NOTES_DIR" ]]; then
  BACKUP_DIR="${NOTES_DIR}.bak.$(date +%Y%m%d%H%M%S)"
  echo "Note: $NOTES_DIR already exists, moving it to: $BACKUP_DIR"
  mv "$NOTES_DIR" "$BACKUP_DIR"
fi

"$SCRIPT_DIR/scripts/decrypt_folder.sh" "$ARCHIVE" "$SCRIPT_DIR"

echo "Notes decrypted into: $NOTES_DIR"
