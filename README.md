# MonsterSanctuaryBackups

Timestamped backups of Monster Sanctuary save files on Linux and Steam Deck, run automatically in
the background.

The game stores saves in `~/.local/share/Monster Sanctuary/<steam-id>/Savegame*.dat`, where the
directory name is a random-looking Steam ID. The script finds it automatically, backs up every save
slot, and skips writing a copy when nothing changed since the last run.

## Install

One command, on Linux or Steam Deck:

```bash
curl -fsSL https://raw.githubusercontent.com/valentecaio/MonsterSanctuaryBackups/main/install.sh | bash
```

This downloads `ms-backup.sh` to `~/.local/bin/`, schedules it **every 15 minutes**, and takes a
first backup right away. Re-run it any time to update — it replaces the existing schedule rather
than adding a second one.

Backups land in:

```
~/.local/share/Monster Sanctuary/backups/<steam-id>/Savegame1_YYYYMMDD-HHMMSS.dat
```

## Steam Deck / SteamOS

The same command works. Run it from **Desktop Mode**:

1. **Steam** button → **Power** → **Switch to Desktop**
2. Open **Konsole** (application launcher, bottom left → System → Konsole)
3. Paste the install command above
4. **Steam** icon on the desktop → back to Game Mode

Nothing to install as root, and nothing outside your home directory — so it survives SteamOS
updates, which replace the whole system partition.

SteamOS ships no cron, so the installer detects this and uses a **systemd user timer** instead. That
happens automatically; the command is identical on both systems.

**If the game runs through Proton** rather than the native Linux build, saves are inside the Proton
prefix instead of the path above. Check with:

```bash
ls ~/.local/share/"Monster Sanctuary"/*/Savegame*.dat 2>/dev/null \
  || find ~/.local/share/Steam/steamapps/compatdata -name 'Savegame*.dat' 2>/dev/null
```

If it's the second one, re-run the installer with the directory *containing* the `<steam-id>` folder:

```bash
curl -fsSL https://raw.githubusercontent.com/valentecaio/MonsterSanctuaryBackups/main/install.sh \
  | SAVE_ROOT="/path/from/the/find/above" bash
```

## Restore

With the game closed, copy the backup you want over the save file:

```bash
cp ~/.local/share/"Monster Sanctuary"/backups/<steam-id>/Savegame1_20260805-212000.dat \
   ~/.local/share/"Monster Sanctuary"/<steam-id>/Savegame1.dat
```

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `SAVE_ROOT` | `~/.local/share/Monster Sanctuary` | Where the game keeps saves |
| `BACKUP_ROOT` | `$SAVE_ROOT/backups` | Where backups are written |
| `KEEP` | `200` | Backups kept per save slot; older ones are pruned |
| `SCHEDULER` | auto | Force `cron` or `systemd` instead of auto-detecting |

Any of the first three passed to the installer are saved to `~/.config/ms-backup.conf`, because
scheduled runs inherit no environment. Delete that file to go back to defaults.

## Checking on it

```bash
# cron
crontab -l | grep ms-backup
tail ~/.ms-backup.log

# systemd (Steam Deck)
systemctl --user list-timers ms-backup.timer
journalctl --user -u ms-backup.service
```

## Uninstall

```bash
crontab -l 2>/dev/null | grep -Fv ms-backup.sh | crontab -
systemctl --user disable --now ms-backup.timer 2>/dev/null
rm -f ~/.config/systemd/user/ms-backup.{timer,service} ~/.local/bin/ms-backup.sh ~/.config/ms-backup.conf
```

## Note

Backups sit next to the saves, so this protects against the game losing or corrupting a save — not
against losing the disk or the home directory. For that, copy the `backups` folder somewhere else
periodically.
