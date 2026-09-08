#!/usr/bin/env bash
set -euo pipefail

# Decrypt an AES-256 encrypted tar.gz archive back into its original folder.
# Usage: ./decrypt_folder.sh <encrypted_file> <output_parent_dir>
# The folder is extracted as a subdirectory of <output_parent_dir>.

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <encrypted_file> <output_parent_dir>" >&2
  exit 1
fi

ENCRYPTED_FILE="$1"
OUTPUT_DIR="$2"

[[ -f "$ENCRYPTED_FILE" ]] || { echo "Error: encrypted file not found: $ENCRYPTED_FILE" >&2; exit 1; }
[[ -d "$OUTPUT_DIR" ]] || { echo "Error: output directory not found: $OUTPUT_DIR" >&2; exit 1; }

for cmd in tar openssl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: '$cmd' is required." >&2; exit 1; }
done

ENCRYPTED_ABS="$(cd "$(dirname "$ENCRYPTED_FILE")" && pwd)/$(basename "$ENCRYPTED_FILE")"
OUTPUT_ABS="$(cd "$OUTPUT_DIR" && pwd)"
CHECKSUM_FILE="${ENCRYPTED_ABS}.sha256"

if [[ -f "$CHECKSUM_FILE" ]] && command -v sha256sum >/dev/null 2>&1; then
  (cd "$(dirname "$ENCRYPTED_ABS")" && sha256sum -c "$(basename "$CHECKSUM_FILE")" >/dev/null) \
    || { echo "Error: checksum verification failed for $ENCRYPTED_ABS" >&2; exit 1; }
  echo "Checksum verified for: $ENCRYPTED_ABS"
fi

TMP_ARCHIVE="$(mktemp /tmp/decrypted.XXXXXX.tar.gz)"
trap 'rm -f "$TMP_ARCHIVE"' EXIT

echo "Decrypting file: $ENCRYPTED_ABS"
if [[ -z "${ENCRYPTION_PASSWORD:-}" ]]; then
  read -r -s -p "Enter decryption password: " ENCRYPTION_PASSWORD
  echo
fi
export ENCRYPTION_PASSWORD

openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -pass "env:ENCRYPTION_PASSWORD" \
  -in "$ENCRYPTED_ABS" -out "$TMP_ARCHIVE" 2>/dev/null \
  || { echo "Error: decryption failed. Wrong password or corrupted file." >&2; exit 1; }

# pipefail is disabled here: `head` closing the pipe early sends tar a SIGPIPE
# which pipefail would otherwise treat as a failure.
set +o pipefail
ROOT_ENTRY="$(tar -tzf "$TMP_ARCHIVE" | head -n1 | cut -d/ -f1)"
set -o pipefail
if [[ -n "$ROOT_ENTRY" && -e "$OUTPUT_ABS/$ROOT_ENTRY" ]]; then
  echo "Error: extraction target already exists: $OUTPUT_ABS/$ROOT_ENTRY" >&2
  echo "Move/remove it first." >&2
  exit 1
fi

echo "Extracting to: $OUTPUT_ABS"
tar -xzf "$TMP_ARCHIVE" -C "$OUTPUT_ABS"
echo "Done. Folder restored in: $OUTPUT_ABS/$ROOT_ENTRY"
