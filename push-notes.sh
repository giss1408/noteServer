#!/usr/bin/env bash
set -euo pipefail

# Encrypt the notes folder and push the encrypted archive to GitHub.
# Usage: ./push-notes.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTES_DIR="$SCRIPT_DIR/notesServer_enc_dec"
ARCHIVE="$SCRIPT_DIR/notesServer_enc"

[[ -d "$NOTES_DIR" ]] || { echo "Error: notes folder not found: $NOTES_DIR" >&2; exit 1; }

"$SCRIPT_DIR/scripts/encrypt_folder.sh" "$NOTES_DIR" "$ARCHIVE"

cd "$SCRIPT_DIR"
git add notesServer_enc notesServer_enc.sha256

if git diff --cached --quiet; then
  echo "No changes to push."
  exit 0
fi

git commit -m "Update encrypted notes"
git push

echo "Notes encrypted and pushed to GitHub."
