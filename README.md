# MonsterSanctuaryBackups

Timestamped backups of Monster Sanctuary save files on Linux, run automatically by cron.

The game stores saves in `~/.local/share/Monster Sanctuary/<steam-id>/Savegame*.dat`, where the
directory name is a random-looking Steam ID. The script finds it automatically, backs up every save
slot, and skips writing a copy when nothing changed since the last run.

## Install

One command on the machine with the game installed:

```bash
curl -fsSL https://raw.githubusercontent.com/valentecaio/MonsterSanctuaryBackups/main/install.sh | bash
```

This downloads `ms-backup.sh` to `~/.local/bin/`, adds a cronjob that runs it **every 15 minutes**,
and takes a first backup right away. Re-run it any time to update — it replaces the old cron entry
rather than adding a second one.

Backups land in:

```
~/.local/share/Monster Sanctuary/backups/<steam-id>/Savegame1_YYYYMMDD-HHMMSS.dat
```

Cron output goes to `~/.ms-backup.log`.

## Restore

Copy the backup you want back over the save file, with the game closed:

```bash
cp ~/.local/share/"Monster Sanctuary"/backups/<steam-id>/Savegame1_20260805-212000.dat \
   ~/.local/share/"Monster Sanctuary"/<steam-id>/Savegame1.dat
```

## Configuration

Environment variables, useful for a manual run:

| Variable | Default | Meaning |
| --- | --- | --- |
| `SAVE_ROOT` | `~/.local/share/Monster Sanctuary` | Where the game keeps saves |
| `BACKUP_ROOT` | `$SAVE_ROOT/backups` | Where backups are written |
| `KEEP` | `200` | Backups kept per save slot; older ones are pruned |

## Uninstall

```bash
crontab -l | grep -Fv ms-backup.sh | crontab -
rm ~/.local/bin/ms-backup.sh
```

## Note

Backups sit next to the saves, so this protects against the game losing or corrupting a save — not
against losing the disk or the home directory. For that, copy the `backups` folder somewhere else
periodically.
