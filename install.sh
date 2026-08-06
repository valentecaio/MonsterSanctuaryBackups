#!/usr/bin/env bash
# Installs ms-backup.sh from GitHub and a cronjob that runs it every 15 minutes.
# Idempotent: re-running replaces the script and the existing cron entry.
#
#   curl -fsSL https://raw.githubusercontent.com/valentecaio/MonsterSanctuaryBackups/main/install.sh | bash

set -euo pipefail

REPO="${REPO:-valentecaio/MonsterSanctuaryBackups}"
REF="${REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$REF"
TARGET="${TARGET:-$HOME/.local/bin/ms-backup.sh}"
LOG="${LOG:-$HOME/.ms-backup.log}"

mkdir -p "$(dirname "$TARGET")"

# Download to a temp file first so a failed fetch can't clobber a working script.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW_BASE/ms-backup.sh" -o "$tmp"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp" "$RAW_BASE/ms-backup.sh"
else
    echo "need curl or wget" >&2
    exit 1
fi

# Sanity-check what we got before trusting it.
head -n1 "$tmp" | grep -q '^#!' || { echo "downloaded file is not a script" >&2; exit 1; }
bash -n "$tmp" || { echo "downloaded script failed syntax check" >&2; exit 1; }

install -m 755 "$tmp" "$TARGET"
echo "installed: $TARGET"

if ! command -v crontab >/dev/null 2>&1; then
    echo "crontab not found - install cron, then re-run this installer" >&2
    exit 1
fi

# Replace any previous entry for this script.
CRON_LINE="*/15 * * * * $TARGET >> $LOG 2>&1"
( crontab -l 2>/dev/null | grep -Fv 'ms-backup.sh' || true; echo "$CRON_LINE" ) | crontab -
echo "cronjob installed (every 15 min), logging to $LOG"

# Run once now so the first backup exists immediately.
"$TARGET" || echo "note: first run found no save files - start the game once, then wait for cron" >&2
