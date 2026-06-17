# yufengjin.github.io — project notes

Personal academic site (Jon Barron template, table-based static HTML) served via **GitHub Pages**
(`git@github.com:YufengJin/yufengjin.github.io.git`, branch `main`). No build step — plain HTML/CSS.

## Layout
- `index.html` — homepage (bio + **Research** = my own papers). Footer links to **Paper Notes**.
- `projects/<name>/` — per-project pages + `resources/` (figures, videos).
- `images/` — homepage assets.
- `.nojekyll` — serve as-is (no Jekyll).

## Paper Notes (separate repo)
**Paper Notes moved out of this repo** into its own GitHub Pages project site:
**`git@github.com:YufengJin/paper-snapshots.git`** → served at `https://yufengjin.github.io/paper-snapshots/`
(locally at `/Users/yjin/Documents/paper-snapshots/`). The homepage footer links there via
`<a href="/paper-snapshots/">`. The poster pipeline (`pipeline/`) and the `paper-notes` /
`paper-poster` skills now live in that repo — add/generate posters there, not here.

## Asset rules (keep the repo lean)
- **Never commit large raw files.** Images → WebP (`cwebp -q 80-85 -resize 1280-1600 0`); videos → `ffmpeg -crf 30 -vf scale≤1280 -movflags +faststart`.
- Target: keep any committed asset well under ~9MB; future big videos → external host / Git LFS, not git history.
- The practical ceiling is the GitHub Pages **1GB built-site** limit.

## Gotchas
- `CNAME` currently says `jonbarron.info` (template leftover — not my domain). Site still serves at `yufengjin.github.io`; consider deleting `CNAME`.
- All internal links are **relative** — keep them that way so the site is domain-agnostic. (Exception: the Paper Notes footer link is the absolute same-domain path `/paper-snapshots/`, since that's a separate Pages site.)
