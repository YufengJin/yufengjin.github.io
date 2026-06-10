# yufengjin.github.io — project notes

Personal academic site (Jon Barron template, table-based static HTML) served via **GitHub Pages**
(`git@github.com:YufengJin/yufengjin.github.io.git`, branch `main`). No build step — plain HTML/CSS.

## Layout
- `index.html` — homepage (bio + **Research** = my own papers). Footer links to **Paper Notes**.
- `projects/<name>/` — per-project pages + `resources/` (figures, videos).
- `images/` — homepage assets.
- `papers/` — **Paper Notes**: 中文 illustrated posters of papers I read (generated, see below).
- `.claude/skills/paper-poster/` — the project skill that builds posters (local only; `.claude/` is gitignored).
- `.nojekyll` — serve as-is (no Jekyll).

## Paper Notes (`papers/`)
Each `papers/<slug>/` has `index.html` (中文, WebP figures) + `img/*.webp` + `meta.json`.
The landing `papers/index.html` is **generated** — do NOT hand-edit it.

**meta.json** is the source of truth per poster: `{slug,title,arxiv_id,url,category,keywords[],summary_zh,date,source}`.
`category` = one of **4 broad buckets (大类, coarse only)**: `机器人 · Robotics` · `计算机视觉 · Computer Vision` · `生成模型 · Generative Models` · `理论与优化 · Theory & Optimization`.
Fine-grained sub-topics are NOT new categories — they live in `keywords[]`, which `build_index.py` turns into the clickable tag filter (top tag bar + per-card chips) on `papers/index.html`.

**Conventions** (enforced by the `paper-poster` skill): body in 中文, keep academic terms/metrics/quotes in English;
all numbers verbatim from the paper (no fabrication); every poster has an arXiv/source link (header+footer) and 6–10 keywords;
sections = 动机 / 方法 / 实验 / 局限性.

## Generation & publish pipeline
Source + tooling live **outside this repo** (private, heavy) at `~/Downloads/papers/posters/`:
- `bin/run_inbox.sh` — drop a PDF in `_inbox/` or add an arXiv id/url/title to `_inbox/queue.txt`, then run it → generates the poster (Sonnet via `claude -p`, following the project skill).
- `bin/publish_to_site.sh` — WebP-compresses figures + copies `<slug>/{index.html,img,meta.json}` into this repo's `papers/`, then rebuilds `papers/index.html` (`bin/build_index.py`, `POSTERS_ROOT` env).
- Then commit + push here; Pages redeploys.

To add a paper, end to end:
```bash
echo "<arxiv-id|url|title>" >> ~/Downloads/papers/posters/_inbox/queue.txt   # or drop a PDF in _inbox/
~/Downloads/papers/posters/bin/run_inbox.sh
~/Downloads/papers/posters/bin/publish_to_site.sh
git add papers && git commit -m "papers: add <slug>" && git push
```

## Asset rules (keep the repo lean — see storage note)
- **Never commit large raw files.** Images → WebP (`cwebp -q 80-85 -resize 1280-1600 0`); videos → `ffmpeg -crf 30 -vf scale≤1280 -movflags +faststart`. Posters are WebP-only.
- Target: keep any committed asset well under ~9MB; future big videos → external host / Git LFS, not git history.
- Repo today ≈ `.git` 179MB + working tree ~49MB (after a one-time history rewrite). At ~1 poster/day (~0.4MB each) ≈ +150MB/yr → comfortable for years; the practical ceiling is the GitHub Pages **1GB built-site** limit.

## Gotchas
- `CNAME` currently says `jonbarron.info` (template leftover — not my domain). Site still serves at `yufengjin.github.io`; consider deleting `CNAME`.
- All internal links are **relative** — keep them that way so the site is domain-agnostic.
