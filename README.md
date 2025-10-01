# cleanup-tool

Simple, safe script to **list** (dry-run) or **delete** files older than N days from common temp/cache directories.

> Built for personal system cleanup. ⚠️ This tool deletes files when run with `--apply`. Always test with dry-run first.

## Features
- Dry-run by default (lists candidate files).
- `--apply` to actually delete (requires confirmation).
- Adjustable age threshold with `--days N`.
- Add/remove custom targets.
- Optional cleanup of user Trash.

## Usage examples

```bash
# dry-run (safe)
./cleanup.sh

# dry-run for 30 days
./cleanup.sh --days 30

# actually delete (will ask for "yes")
sudo ./cleanup.sh --apply --days 30

# add a custom target
./cleanup.sh --target "$HOME/.local/share/Trash/files" --days 14

# override default targets with comma-separated list
./cleanup.sh --targets "/tmp,$HOME/.cache" --days 10 --apply
