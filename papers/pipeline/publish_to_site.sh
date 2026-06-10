#!/usr/bin/env bash
# Publish posters into this repo as WebP (raw source stays in $POSTERS_SRC, never committed).
# For each <slug>/: webp-convert figures, rewrite HTML img src .png/.jpg -> .webp, copy meta.json.
# Then rebuild the site landing page. Idempotent: skips images already up-to-date.
# Usage: papers/pipeline/publish_to_site.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${POSTERS_SRC:-/Users/yjin/Downloads/papers/posters}"   # external source posters (raw figs)
SITE="${SITE_DIR:-$(cd "$HERE/../.." && pwd)}"               # repo root (pipeline -> papers -> repo)
DST="$SITE/papers"
QUAL="${WEBP_QUALITY:-80}"
MAXW="${WEBP_MAXWIDTH:-1280}"
command -v cwebp >/dev/null || { echo "need cwebp (brew install webp)"; exit 1; }
mkdir -p "$DST"

newer(){ [ "$1" -nt "$2" ] || [ ! -f "$2" ]; }     # $1 newer than $2, or $2 missing

n_posters=0; n_imgs=0
for d in "$SRC"/*/; do
  slug="$(basename "$d")"
  case "$slug" in _*|bin|pipeline) continue;; esac
  [ -f "$d/index.html" ] && [ -f "$d/meta.json" ] || continue
  mkdir -p "$DST/$slug/img"

  # 1) figures -> webp (cap width, skip if up-to-date)
  shopt -s nullglob
  for img in "$d"img/*.png "$d"img/*.jpg "$d"img/*.jpeg "$d"img/*.PNG "$d"img/*.JPG; do
    base="$(basename "$img")"; out="$DST/$slug/img/${base%.*}.webp"
    if newer "$img" "$out"; then
      cwebp -quiet -q "$QUAL" -resize "$MAXW" 0 "$img" -o "$out" 2>/dev/null \
        && n_imgs=$((n_imgs+1)) || echo "  ! cwebp failed: $img"
    fi
  done
  # carry over any figures that were already webp
  for img in "$d"img/*.webp; do [ -e "$img" ] && cp -f "$img" "$DST/$slug/img/"; done

  # 2) HTML with rewritten src (.png/.jpg/.jpeg -> .webp), only for img/ paths
  sed -E 's#(src="img/[^"]+)\.(png|jpg|jpeg|PNG|JPG)"#\1.webp"#g' "$d/index.html" > "$DST/$slug/index.html"

  # 3) meta.json
  cp -f "$d/meta.json" "$DST/$slug/meta.json"
  n_posters=$((n_posters+1))
done

# 4) rebuild the site landing page from the published meta.json files
POSTERS_ROOT="$DST" python3 "$HERE/build_index.py"

echo "published: $n_posters posters, $n_imgs new webp -> $DST"
du -sh "$DST" 2>/dev/null | sed 's/^/papers size: /'
