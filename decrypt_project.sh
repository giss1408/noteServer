#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
PARENT_DIR="$(dirname "$PROJECT_DIR")"

ARCHIVE_FILE="${1:-$PARENT_DIR/${PROJECT_NAME}_enc}"
RESTORE_PARENT_DIR="${2:-$PARENT_DIR}"

"$SCRIPT_DIR/decrypt_folder.sh" "$ARCHIVE_FILE" "$RESTORE_PARENT_DIR"

echo "Project decrypted from: $ARCHIVE_FILE"
echo "Restored under: $RESTORE_PARENT_DIR"
