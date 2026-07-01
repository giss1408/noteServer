#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
PARENT_DIR="$(dirname "$PROJECT_DIR")"

resolve_decrypt_helper() {
	if [[ -x "$SCRIPT_DIR/decrypt_folder.sh" ]]; then
		echo "$SCRIPT_DIR/decrypt_folder.sh"
		return 0
	fi
	if [[ -x "$SCRIPT_DIR/start-scripts/decrypt_folder.sh" ]]; then
		echo "$SCRIPT_DIR/start-scripts/decrypt_folder.sh"
		return 0
	fi
	if [[ -x "$PROJECT_DIR/start-scripts/decrypt_folder.sh" ]]; then
		echo "$PROJECT_DIR/start-scripts/decrypt_folder.sh"
		return 0
	fi
	return 1
}

DECRYPT_HELPER="$(resolve_decrypt_helper || true)"
if [[ -z "$DECRYPT_HELPER" ]]; then
	echo "Error: could not locate decrypt_folder.sh." >&2
	echo "Expected in one of:" >&2
	echo "  - $SCRIPT_DIR/decrypt_folder.sh" >&2
	echo "  - $SCRIPT_DIR/start-scripts/decrypt_folder.sh" >&2
	echo "  - $PROJECT_DIR/start-scripts/decrypt_folder.sh" >&2
	exit 1
fi

ARCHIVE_FILE="${1:-$PARENT_DIR/${PROJECT_NAME}_enc}"
RESTORE_PARENT_DIR="${2:-$PARENT_DIR}"

"$DECRYPT_HELPER" "$ARCHIVE_FILE" "$RESTORE_PARENT_DIR"

echo "Project decrypted from: $ARCHIVE_FILE"
echo "Restored under: $RESTORE_PARENT_DIR"
