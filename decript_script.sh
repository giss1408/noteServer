#!/usr/bin/env bash
set -euo pipefail

# Decrypt an encrypted tar.gz file and extract the original folder.
# Usage: ./decrypt_folder.sh <encrypted_file> [output_directory]
#
# Behavior:
# - If output_directory is provided: extract archive as-is into that directory.
# - If output_directory is omitted: create a folder based on encrypted filename
#   and extract inside it.

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <encrypted_file> [output_directory]" >&2
  exit 1
fi

ENCRYPTED_FILE="$1"
OUTPUT_DIR="${2:-}"
OUTPUT_DIR_PROVIDED=false
if [[ -n "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR_PROVIDED=true
fi

if [[ ! -f "$ENCRYPTED_FILE" ]]; then
  echo "Error: encrypted file not found: $ENCRYPTED_FILE" >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "Error: 'tar' is required." >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: 'openssl' is required." >&2
  exit 1
fi

ENCRYPTED_ABS="$(cd "$(dirname "$ENCRYPTED_FILE")" && pwd)/$(basename "$ENCRYPTED_FILE")"
CHECKSUM_FILE="${ENCRYPTED_ABS}.sha256"

if [[ -f "$CHECKSUM_FILE" ]]; then
  if ! command -v sha256sum >/dev/null 2>&1; then
    echo "Error: checksum file found but 'sha256sum' is not available." >&2
    exit 1
  fi

  if ! (cd "$(dirname "$ENCRYPTED_ABS")" && sha256sum -c "$(basename "$CHECKSUM_FILE")" >/dev/null 2>&1); then
    echo "Error: checksum verification failed for $ENCRYPTED_ABS" >&2
    exit 1
  fi

  echo "Checksum verified for: $ENCRYPTED_ABS"
fi

if [[ "$OUTPUT_DIR_PROVIDED" == false ]]; then
  # Derive folder name from encrypted file name.
  base_name="$(basename "$ENCRYPTED_FILE")"
  base_name="${base_name%.tar.gz.enc}"
  base_name="${base_name%.tgz.enc}"
  base_name="${base_name%.enc}"

  OUTPUT_DIR="$(dirname "$ENCRYPTED_ABS")/$base_name"
  if [[ -e "$OUTPUT_DIR" ]]; then
    candidate="${OUTPUT_DIR}_dec"
    n=1
    while [[ -e "$candidate" ]]; do
      candidate="${OUTPUT_DIR}_dec_${n}"
      n=$((n + 1))
    done
    OUTPUT_DIR="$candidate"
    echo "Info: default target already exists, using: $OUTPUT_DIR"
  fi
fi

if [[ "$OUTPUT_DIR_PROVIDED" == true && ! -d "$OUTPUT_DIR" ]]; then
  echo "Error: output directory not found: $OUTPUT_DIR" >&2
  exit 1
fi

if [[ "$OUTPUT_DIR_PROVIDED" == true ]]; then
  OUTPUT_ABS="$(cd "$OUTPUT_DIR" && pwd)"
else
  OUTPUT_ABS="$OUTPUT_DIR"
fi
TMP_ARCHIVE="$(mktemp /tmp/decrypted.XXXXXX.tar.gz)"

cleanup() {
  rm -f "$TMP_ARCHIVE"
}
trap cleanup EXIT

echo "Decrypting file: $ENCRYPTED_ABS"
if [[ -z "${ENCRYPTION_PASSWORD:-}" ]]; then
  read -r -s -p "Enter decryption password: " ENCRYPTION_PASSWORD
  echo
fi

export ENCRYPTION_PASSWORD

if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -pass "env:ENCRYPTION_PASSWORD" \
  -in "$ENCRYPTED_ABS" -out "$TMP_ARCHIVE" 2>/dev/null; then
  echo "Error: decryption failed. Wrong password or corrupted file." >&2
  exit 1
fi

if [[ "$OUTPUT_DIR_PROVIDED" == true ]]; then
  # Existing behavior when user chooses output directory.
  ROOT_ENTRY="$(tar -tzf "$TMP_ARCHIVE" | head -n1 | cut -d/ -f1)"
  if [[ -n "$ROOT_ENTRY" && -e "$OUTPUT_ABS/$ROOT_ENTRY" ]]; then
    echo "Error: extraction target already exists: $OUTPUT_ABS/$ROOT_ENTRY" >&2
    echo "Move/remove it first, or use a different output directory." >&2
    exit 1
  fi

  echo "Extracting to: $OUTPUT_ABS"
  tar -xzf "$TMP_ARCHIVE" -C "$OUTPUT_ABS"
  echo "Done. Folder restored in: $OUTPUT_ABS"
else
  # New behavior: extract into a temp folder, then atomically move to final name.
  TEMP_OUT_DIR="$(mktemp -d "$(dirname "$OUTPUT_ABS")/.decrypt.XXXXXX")"
  echo "Extracting to: $OUTPUT_ABS"
  tar -xzf "$TMP_ARCHIVE" -C "$TEMP_OUT_DIR" --strip-components=1
  mv "$TEMP_OUT_DIR" "$OUTPUT_ABS"
  echo "Done. Folder restored in: $OUTPUT_ABS"
fi
