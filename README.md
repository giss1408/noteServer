# Note Server

Notes live in `notesServer_enc_dec/` (plaintext, never committed — see
`.gitignore`). Only the encrypted archive (`notesServer_enc` +
`notesServer_enc.sha256`) is tracked in this git repo.

## Prerequisites
`openssl`, `tar`, `sha256sum` (optional).

## Usage

```bash
# Encrypt notesServer_enc_dec/ and push the archive to GitHub
./push-notes.sh

# Pull the latest archive from GitHub and decrypt it
./pull-notes.sh
```

Both scripts prompt for the encryption password interactively. For
automation, set it beforehand: `export ENCRYPTION_PASSWORD='your-password'`.

Files/folders inside `notesServer_enc_dec/.encryptignore` are excluded from
the encrypted archive (e.g. `site/`, `mkdocs-env/`, `__pycache__/`).

To view/edit the notes locally (docs site, docker-compose), see
`notesServer_enc_dec/start-scripts/README.md`.
