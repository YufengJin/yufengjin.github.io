#!/usr/bin/env bash
# Process everything in the inbox — PDFs, paper screenshots (.jpg/.png), .txt/.bib reference
# lists (arXiv ids extracted), and queue.txt lines — then rebuild the source index.
# These scripts are version-controlled here in the repo; the working dir (inbox + raw figure
# sources) is in-repo but git-ignored at $POSTERS_SRC (default papers/_src). No external deps.
# Idempotent: a dedup ledger (_processed/processed.tsv) skips already-done inputs.
# Manual trigger:  papers/pipeline/run_inbox.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
POSTERS="${POSTERS_SRC:-$(cd "$HERE/.." && pwd)/_src}"   # in-repo working dir (papers/_src)
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

# 1b) Paper screenshots/images dropped in _inbox/ (key = filename). add_paper reads the
#     image, lifts the title, then finds the paper on arXiv. Quoted globs handle spaces/中文 names.
for img in "$INBOX"/*.jpg "$INBOX"/*.jpeg "$INBOX"/*.png "$INBOX"/*.JPG "$INBOX"/*.JPEG "$INBOX"/*.PNG; do
  base="$(basename "$img")"
  process "img:$base" "$img" "mv -f \"$img\" \"$PROC/\" 2>/dev/null || true"
done

# 1c) Reference lists (.txt/.bib): extract every arXiv id and process each (keyed q:<id> so it
#     dedups against queue.txt), then archive the list. queue.txt itself is handled in step 2.
for ref in "$INBOX"/*.txt "$INBOX"/*.bib; do
  base="$(basename "$ref")"
  case "$base" in queue.txt) continue;; esac
  ids="$(grep -oiE 'arxiv[.:]?[0-9]{4}\.[0-9]{4,5}' "$ref" | grep -oE '[0-9]{4}\.[0-9]{4,5}' | sort -u)"
  if [ -z "$ids" ]; then log "no arXiv ids in $base; leaving in inbox"; continue; fi
  log "ref $base -> $(printf '%s\n' "$ids" | grep -c .) arXiv ids"
  while IFS= read -r id; do [ -n "$id" ] && process "q:$id" "$id"; done <<< "$ids"
  mv -f "$ref" "$PROC/" 2>/dev/null || true
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
