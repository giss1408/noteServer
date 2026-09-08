#!/usr/bin/env bash
set -euo pipefail

# Encrypt a folder into a single AES-256 encrypted tar.gz archive.
# Usage: ./encrypt_folder.sh <folder_path> <output_file>

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <folder_path> <output_file>" >&2
  exit 1
fi

SOURCE_DIR="$1"
OUTPUT_FILE="$2"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: folder not found: $SOURCE_DIR" >&2
  exit 1
fi

for cmd in tar openssl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: '$cmd' is required." >&2; exit 1; }
done

SOURCE_ABS="$(cd "$SOURCE_DIR" && pwd)"
SOURCE_NAME="$(basename "$SOURCE_ABS")"
SOURCE_PARENT="$(dirname "$SOURCE_ABS")"
OUTPUT_ABS="$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")"

TMP_ARCHIVE="$(mktemp /tmp/"$SOURCE_NAME".XXXXXX.tar.gz)"
trap 'rm -f "$TMP_ARCHIVE"' EXIT

# Exclude patterns listed in <folder>/.encryptignore (relative to folder root).
TAR_EXCLUDES=()
IGNORE_FILE="$SOURCE_ABS/.encryptignore"
if [[ -f "$IGNORE_FILE" ]]; then
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    pattern="${pattern#./}"
    pattern="${pattern%/}"
    TAR_EXCLUDES+=("--exclude=${SOURCE_NAME}/${pattern}")
  done < "$IGNORE_FILE"
fi

echo "Creating archive from: $SOURCE_ABS"
tar -czf "$TMP_ARCHIVE" "${TAR_EXCLUDES[@]}" -C "$SOURCE_PARENT" "$SOURCE_NAME"

if [[ -z "${ENCRYPTION_PASSWORD:-}" ]]; then
  read -r -s -p "Enter encryption password: " ENCRYPTION_PASSWORD
  echo
  read -r -s -p "Confirm encryption password: " ENCRYPTION_PASSWORD_CONFIRM
  echo
  [[ "$ENCRYPTION_PASSWORD" == "$ENCRYPTION_PASSWORD_CONFIRM" ]] || { echo "Error: passwords do not match." >&2; exit 1; }
fi
export ENCRYPTION_PASSWORD

echo "Encrypting to: $OUTPUT_ABS"
openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt \
  -pass "env:ENCRYPTION_PASSWORD" \
  -in "$TMP_ARCHIVE" -out "$OUTPUT_ABS"

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$(dirname "$OUTPUT_ABS")" && sha256sum "$(basename "$OUTPUT_ABS")" > "$(basename "$OUTPUT_ABS").sha256")
fi

echo "Done. Encrypted file created: $OUTPUT_ABS"
