#!/usr/bin/env bash
# Generate ONE Chinese paper poster from an input, via headless claude -p.
# Input may be: a local PDF path | an image/screenshot of a paper | an arXiv id | a URL | a title.
# Writes <slug>/index.html + img/ + meta.json into $POSTERS_SRC. Does NOT touch the index.
# Usage: papers/pipeline/add_paper.sh "<input>"
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="${CLAUDE_BIN:-/Users/yjin/.local/bin/claude}"
SITE="${SITE_DIR:-$(cd "$HERE/../.." && pwd)}"       # repo root (pipeline -> papers -> repo)
SKILL="$SITE/.claude/skills/paper-poster/SKILL.md"   # project skill (local, gitignored)
POSTERS="${POSTERS_SRC:-$(cd "$HERE/.." && pwd)/_src}"  # in-repo working dir (papers/_src)
PAPERS="$(dirname "$POSTERS")"
TODAY="$(date +%F)"
INPUT="${1:?usage: add_paper.sh <pdf|arxiv-id|url|title>}"

# Resolve a relative PDF path to absolute so the headless agent can read it.
if [ -f "$INPUT" ]; then INPUT="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"; fi

# The 4 broad buckets (大类). Fine-grained topic is expressed via keywords, not the category.
CATS='机器人 · Robotics | 计算机视觉 · Computer Vision | 生成模型 · Generative Models | 理论与优化 · Theory & Optimization'

read -r -d '' PROMPT <<EOF
You are generating ONE Chinese-language paper poster. Work autonomously; never ask questions.

FIRST read and follow this skill completely: $SKILL
(template: $SITE/.claude/skills/paper-poster/assets/poster-template.html)

INPUT (a PDF path, an image/screenshot of a paper, an arXiv id, a URL, or a title): $INPUT

Do all of this:
1. Identify the paper. If it is an arXiv id/url, verify it (fetch arxiv.org/abs/<id>, confirm title). If a PDF OR an image/screenshot path, Read it — for an image, lift the paper title (and authors) off the screenshot — then WebSearch that title to find the arXiv id. If a title/url, WebSearch to find the arXiv id. Once you have the id, prefer the arXiv HTML render for clean figures (per the skill); fall back to the local PDF/image only if no arXiv source exists.
2. Choose a short, url-safe lowercase slug (e.g. "g3t", "pi0", "shortcut-models").
3. Generate the 中文 poster to $POSTERS/<slug>/index.html with figures in $POSTERS/<slug>/img/ — cover 动机/方法/实验/局限性, 6-10 keyword chips + <meta name=keywords>, and the original-paper link in header AND footer. Body in 中文, keep academic terms/metrics/quotes in English. All numbers verbatim from the paper.
4. ALSO write $POSTERS/<slug>/meta.json with EXACTLY these fields:
   {"slug","title","arxiv_id","url","category","keywords"(6-10 array),"summary_zh"(one 中文 sentence),"date":"$TODAY","source"}
   category MUST be exactly one of the 4 broad buckets: $CATS
   (the bucket is coarse — put the specific sub-topic in keywords, not the category)
   url = the canonical paper link (arxiv abs, else project/OpenReview). arxiv_id = "" if none.
5. Do NOT edit the collection index.html (a separate build script handles it).

If the paper already exists at $POSTERS/<slug>/meta.json, you may stop early. Finish by printing the slug you used.
EOF

echo "[add_paper] input=$INPUT  date=$TODAY  src=$POSTERS"
before="$(ls -1 "$POSTERS" 2>/dev/null)"

RUN=("$CLAUDE" -p "$PROMPT" --model sonnet
     --allowedTools Bash Read Write WebFetch WebSearch
     --add-dir "$PAPERS" --add-dir "$SITE" --output-format text)
# Optional wall-clock cap if GNU coreutils' gtimeout is installed.
if command -v gtimeout >/dev/null 2>&1; then RUN=(gtimeout 900 "${RUN[@]}"); fi

# Run from the repo root so the project + global CLAUDE.md and .claude/skills/ are auto-loaded
# (CLAUDE.md is discovered by walking up from cwd; --add-dir alone does NOT load it).
( cd "$SITE" && "${RUN[@]}" )
rc=$?

after="$(ls -1 "$POSTERS" 2>/dev/null)"
newslug="$(comm -13 <(echo "$before" | sort) <(echo "$after" | sort) | grep -vE '^(_|bin$)' | head -1)"

# Verify a complete poster exists (new dir, or any dir touched in this run).
verify() { [ -f "$POSTERS/$1/index.html" ] && [ -f "$POSTERS/$1/meta.json" ]; }
if [ -n "$newslug" ] && verify "$newslug"; then
  echo "[add_paper] OK → $newslug"; echo "$newslug"; exit 0
fi
# Fallback: newest meta.json written today
recent="$(find "$POSTERS" -name meta.json -newermt "$TODAY 00:00:00" 2>/dev/null | head -1)"
if [ -n "$recent" ]; then s="$(basename "$(dirname "$recent")")"; if verify "$s"; then
  echo "[add_paper] OK (existing/updated) → $s"; echo "$s"; exit 0; fi; fi

echo "[add_paper] FAILED (rc=$rc, no complete poster produced)" >&2
exit 1
