#!/usr/bin/env bash
# Backs up Monster Sanctuary save files with a timestamp in the name.
# Safe to run repeatedly (e.g. from cron); skips writing a new copy when
# nothing changed since the last backup.

set -euo pipefail

SAVE_ROOT="${SAVE_ROOT:-$HOME/.local/share/Monster Sanctuary}"
BACKUP_ROOT="${BACKUP_ROOT:-$SAVE_ROOT/backups}"
KEEP="${KEEP:-200}"   # backups to keep per save file

stamp=$(date +%Y%m%d-%H%M%S)
found=0

# The profile directory has a random (Steam ID) name, so glob for it.
while IFS= read -r -d '' save; do
    found=1
    profile=$(basename "$(dirname "$save")")
    base=$(basename "$save" .dat)
    dest_dir="$BACKUP_ROOT/$profile"
    mkdir -p "$dest_dir"

    # Skip if the newest existing backup is byte-identical.
    latest=$(ls -1t "$dest_dir/$base"_*.dat 2>/dev/null | head -n1 || true)
    if [ -n "$latest" ] && cmp -s "$save" "$latest"; then
        continue
    fi

    cp -p "$save" "$dest_dir/${base}_${stamp}.dat"
    echo "backed up: $save -> $dest_dir/${base}_${stamp}.dat"

    # Prune oldest beyond KEEP.
    ls -1t "$dest_dir/$base"_*.dat 2>/dev/null | tail -n +$((KEEP + 1)) | while IFS= read -r old; do
        rm -f -- "$old"
    done
done < <(find "$SAVE_ROOT" -mindepth 1 -maxdepth 2 \
    -path "$BACKUP_ROOT" -prune -o \
    -name 'Savegame*.dat' -type f -print0 2>/dev/null)

if [ "$found" -eq 0 ]; then
    echo "no save files found under $SAVE_ROOT" >&2
    exit 1
fi
