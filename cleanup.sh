#!/usr/bin/env bash
set -euo pipefail

# cleanup.sh
# Simple cleanup tool: list (dry-run) or delete files older than N days in target directories.
# Defaults: dry-run, 7 days, targets = /tmp, /var/tmp, $HOME/.cache
#
# Usage:
#   ./cleanup.sh                # dry-run
#   ./cleanup.sh --days 30     # dry-run, 30 days
#   sudo ./cleanup.sh --apply  # actually delete (will ask for confirmation)
#   ./cleanup.sh --target /tmp --target "$HOME/.local/share/Trash/files" --apply --days 14

DRY_RUN=true
AGE_DAYS=7
VERBOSE=false
# default targets
TARGETS=(/tmp /var/tmp "$HOME/.cache")

usage() {
  cat <<EOF
Usage: $0 [--apply] [--days N] [--target PATH] [--targets comma,separated] [--verbose] [--help]

  --apply               : actually delete (default: dry-run)
  --days N              : delete files older than N days (default: $AGE_DAYS)
  --target PATH         : add a single target directory (can be used multiple times)
  --targets a,b,c       : comma-separated list of targets (overrides defaults)
  --verbose             : show more output
  --help                : show this message
EOF
  exit 1
}

# parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) DRY_RUN=false; shift ;;
    --days) AGE_DAYS="$2"; shift 2 ;;
    --target) TARGETS+=("$2"); shift 2 ;;
    --targets) IFS=',' read -r -a TARGETS <<< "$2"; shift 2 ;;
    --verbose) VERBOSE=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# safety: require explicit "yes" when deleting (and running interactively)
if ! $DRY_RUN; then
  if [ -t 0 ]; then
    echo "WARNING: --apply will PERMANENTLY delete files older than $AGE_DAYS days in the selected targets."
    echo -n "Type 'yes' to continue: "
    read -r CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
      echo "Aborting. No changes made."
      exit 1
    fi
  fi
fi

printf "\nStarting cleanup-tool (dry-run=%s, days=%s)\n\n" "$DRY_RUN" "$AGE_DAYS"

for t in "${TARGETS[@]}"; do
  # expand ~ if present
  eval tpath="$t"
  if [ -z "$tpath" ]; then
    continue
  fi
  if [ ! -d "$tpath" ]; then
    echo "Skipping $tpath (not present)"
    continue
  fi

  if $DRY_RUN; then
    echo "[DRY-RUN] Files older than $AGE_DAYS days in: $tpath"
    # show a sample (first 50)
    find "$tpath" -mindepth 1 -mtime +"$AGE_DAYS" -print | head -n 50 || true
    echo "  (run with --apply to delete)"
    echo
  else
    echo "Deleting files older than $AGE_DAYS days in: $tpath"
    # Count entries
    count=$(find "$tpath" -mindepth 1 -mtime +"$AGE_DAYS" -print 2>/dev/null | wc -l || true)
    if [ "${count:-0}" -eq 0 ]; then
      echo "  -> Nothing to delete."
      continue
    fi
    echo "  -> Found $count entries. Deleting..."
    # Use find ... -exec rm -rf {} + so we avoid shell expansion issues.
    # NOTE: script won't auto-elevate. Run with sudo if needed.
    find "$tpath" -mindepth 1 -mtime +"$AGE_DAYS" -exec rm -rf -- {} + 2>/dev/null || true
    echo "  -> Done."
    echo
  fi
done

# optional: also clean local Trash (only when explicitly --apply)
if ! $DRY_RUN; then
  TRASH_DIR="$HOME/.local/share/Trash/files"
  if [ -d "$TRASH_DIR" ]; then
    echo "Also emptying Trash files older than $AGE_DAYS days: $TRASH_DIR"
    find "$TRASH_DIR" -mindepth 1 -mtime +"$AGE_DAYS" -exec rm -rf -- {} + 2>/dev/null || true
  fi
fi

echo "Finished."
