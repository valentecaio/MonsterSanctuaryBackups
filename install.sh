#!/usr/bin/env bash
# Installs ms-backup.sh from GitHub and schedules it every 15 minutes with a
# systemd user timer. Works the same on regular Linux and on SteamOS/Steam Deck.
#
#   curl -fsSL https://raw.githubusercontent.com/valentecaio/MonsterSanctuaryBackups/main/install.sh | bash
#
# Idempotent: re-run to update.

set -euo pipefail

REPO="${REPO:-valentecaio/MonsterSanctuaryBackups}"
REF="${REF:-main}"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/$REPO/$REF}"
TARGET="${TARGET:-$HOME/.local/bin/ms-backup.sh}"
UNIT_DIR="$HOME/.config/systemd/user"

have() { command -v "$1" >/dev/null 2>&1; }

have systemctl && systemctl --user show-environment >/dev/null 2>&1 || {
    echo "no systemd user session available - cannot schedule the backup" >&2
    exit 1
}

# ---------------------------------------------------------------- fetch script

mkdir -p "$(dirname "$TARGET")"

# Download to a temp file first so a failed fetch can't clobber a working script.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if have curl; then
    curl -fsSL "$RAW_BASE/ms-backup.sh" -o "$tmp"
elif have wget; then
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

# Persist overrides: the scheduled run gets no environment from this shell.
CONFIG="${CONFIG:-$HOME/.config/ms-backup.conf}"
if [ -n "${SAVE_ROOT:-}${BACKUP_ROOT:-}${KEEP:-}" ]; then
    mkdir -p "$(dirname "$CONFIG")"
    : > "$CONFIG"
    [ -n "${SAVE_ROOT:-}" ]   && printf 'SAVE_ROOT=%q\n'   "$SAVE_ROOT"   >> "$CONFIG"
    [ -n "${BACKUP_ROOT:-}" ] && printf 'BACKUP_ROOT=%q\n' "$BACKUP_ROOT" >> "$CONFIG"
    [ -n "${KEEP:-}" ]        && printf 'KEEP=%q\n'        "$KEEP"        >> "$CONFIG"
    echo "wrote config: $CONFIG"
fi

# ------------------------------------------------------------------- scheduling

# Drop the cron entry left by older versions of this installer, so the backup
# does not end up scheduled twice.
if have crontab && crontab -l 2>/dev/null | grep -qF 'ms-backup.sh'; then
    ( crontab -l 2>/dev/null | grep -Fv 'ms-backup.sh' || true ) | crontab -
    echo "removed old cron entry"
fi

mkdir -p "$UNIT_DIR"

cat > "$UNIT_DIR/ms-backup.service" <<'EOF'
[Unit]
Description=Backup Monster Sanctuary save files

[Service]
Type=oneshot
ExecStart=%h/.local/bin/ms-backup.sh
EOF

cat > "$UNIT_DIR/ms-backup.timer" <<'EOF'
[Unit]
Description=Backup Monster Sanctuary save files every 15 minutes

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now ms-backup.timer
# Keep the timer running when no desktop session is logged in.
loginctl enable-linger "$USER" >/dev/null 2>&1 \
    || echo "note: could not enable linger; timer runs while you are logged in"
echo "scheduled every 15 min, logs: journalctl --user -u ms-backup.service"

# ------------------------------------------------------------------ first run

"$TARGET" || cat >&2 <<EOF
note: no save files found yet - run the game once. If your saves live somewhere
      else, re-run this installer with SAVE_ROOT set to the directory that
      contains the <steam-id> folder.
EOF
