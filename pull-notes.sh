#!/usr/bin/env bash
set -euo pipefail

# Pull the latest encrypted archive from GitHub and decrypt it.
# Usage: ./pull-notes.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTES_DIR="$SCRIPT_DIR/notesServer_enc_dec"
ARCHIVE="$SCRIPT_DIR/notesServer_enc"

cd "$SCRIPT_DIR"
git pull

[[ ! -d "$NOTES_DIR" ]] || { echo "Error: $NOTES_DIR already exists. Remove or rename it before pulling." >&2; exit 1; }

"$SCRIPT_DIR/scripts/decrypt_folder.sh" "$ARCHIVE" "$SCRIPT_DIR"

echo "Notes decrypted into: $NOTES_DIR"
