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

This downloads `ms-backup.sh` to `~/.local/bin/`, schedules it **every 15 minutes** with a systemd
user timer, and takes a first backup right away. Re-run it any time to update — it replaces the
existing schedule rather than adding a second one.

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

Monster Sanctuary has a native Linux build, so it writes to the same path on the Deck as on any
other Linux machine — no Proton prefix to chase.

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
| `KEEP` | `50` | Backups kept per save slot; older ones are pruned |

Passing any of these to the installer saves them to `~/.config/ms-backup.conf`, because scheduled
runs inherit no environment. Delete that file to go back to defaults.

## Checking on it

```bash
systemctl --user list-timers ms-backup.timer   # when it next runs
journalctl --user -u ms-backup.service         # what it did
systemctl --user start ms-backup.service       # run one now
```

## Uninstall

```bash
systemctl --user disable --now ms-backup.timer
rm -f ~/.config/systemd/user/ms-backup.{timer,service} ~/.local/bin/ms-backup.sh ~/.config/ms-backup.conf
systemctl --user daemon-reload
```

## Note

Backups sit next to the saves, so this protects against the game losing or corrupting a save — not
against losing the disk or the home directory. For that, copy the `backups` folder somewhere else
periodically.
