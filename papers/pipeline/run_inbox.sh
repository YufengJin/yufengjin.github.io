#!/usr/bin/env bash
# Process everything in the inbox (PDFs + queue.txt lines), then rebuild the source index.
# These scripts are version-controlled here in the repo; the heavy working dir (inbox + raw
# figure sources) lives OUTSIDE the repo at $POSTERS_SRC (default ~/Downloads/papers/posters).
# Idempotent: a dedup ledger (_processed/processed.tsv) skips already-done inputs.
# Manual trigger:  papers/pipeline/run_inbox.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
POSTERS="${POSTERS_SRC:-/Users/yjin/Downloads/papers/posters}"   # external working dir
INBOX="$POSTERS/_inbox"
PROC="$POSTERS/_processed"
LOGS="$POSTERS/_logs"
LEDGER="$PROC/processed.tsv"
QUEUE="$INBOX/queue.txt"
mkdir -p "$INBOX" "$PROC" "$LOGS"
touch "$LEDGER"
export PATH="/Users/yjin/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

LOG="$LOGS/run-$(date +%F).log"
log(){ echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }
seen(){ cut -f2 "$LEDGER" | grep -Fxq "$1"; }              # key already processed?
record(){ printf '%s\t%s\t%s\t%s\n' "$(date +%F)" "$1" "$2" "$3" >>"$LEDGER"; }

log "=== run_inbox start (src=$POSTERS) ==="
done_n=0; skip_n=0; fail_n=0

process(){            # $1=dedup-key  $2=input-arg  $3=on-success-cleanup(optional cmd)
  local key="$1" input="$2" cleanup="${3:-}"
  if seen "$key"; then log "skip (done): $key"; skip_n=$((skip_n+1)); return; fi
  log "process: $key"
  if slug="$("$HERE/add_paper.sh" "$input" 2>>"$LOG" | tail -1)" && [ -n "$slug" ] \
     && [ -f "$POSTERS/$slug/meta.json" ]; then
     record "$key" "$slug" ok; log "  -> $slug ✓"; done_n=$((done_n+1))
     [ -n "$cleanup" ] && eval "$cleanup"
  else
     record "$key" "-" fail; log "  -> FAILED"; fail_n=$((fail_n+1))
  fi
}

# 1) PDFs dropped in _inbox/  (key = filename; archive to _processed on success)
shopt -s nullglob
for pdf in "$INBOX"/*.pdf "$INBOX"/*.PDF; do
  base="$(basename "$pdf")"
  process "pdf:$base" "$pdf" "mv -f \"$pdf\" \"$PROC/\" 2>/dev/null || true"
done

# 2) queue.txt lines (key = the line itself; lines kept in file, ledger prevents redo)
if [ -f "$QUEUE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue;; esac
    process "q:$line" "$line"
  done < "$QUEUE"
fi

# 3) rebuild the (external) source preview index once; publish_to_site.sh rebuilds the repo one
if [ "$done_n" -gt 0 ]; then
  log "rebuilding source index.html ..."
  POSTERS_ROOT="$POSTERS" python3 "$HERE/build_index.py" 2>&1 | tee -a "$LOG"
else
  log "no new posters; index unchanged"
fi

log "=== done: $done_n new, $skip_n skipped, $fail_n failed ==="
echo "new=$done_n skipped=$skip_n failed=$fail_n  (log: $LOG)"
