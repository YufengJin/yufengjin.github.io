# yufengjin.github.io — project notes

Personal academic site (Jon Barron template, table-based static HTML) served via **GitHub Pages**
(`git@github.com:YufengJin/yufengjin.github.io.git`, branch `main`). No build step — plain HTML/CSS.

## Layout
- `index.html` — homepage (bio + **Research** = my own papers). Footer links to **Study Notes** & **Paper Snapshots**.
- `projects/<name>/` — per-project pages + `resources/` (figures, videos).
- `images/` — homepage assets.
- `.nojekyll` — serve as-is (no Jekyll).

## Sibling sites & local layout
The three sites are **separate GitHub repos** (each with its own remote + Pages), kept side-by-side
locally under `/Users/yjin/Documents/pages/` for convenience — `pages/` is just a folder, **not** a
git repo / monorepo.
- `pages/yufengjin.github.io/` — this repo (root site `yufengjin.github.io`).
- `pages/paper-snapshots/` — Paper Notes → `https://yufengjin.github.io/paper-snapshots/`. Footer link `<a href="/paper-snapshots/">`. Poster pipeline + `paper-notes`/`paper-poster` skills live there — add/generate posters there, not here.
- `pages/learning-notes/` — MkDocs notes → `https://yufengjin.github.io/learning-notes/`. Footer link `<a href="/learning-notes/">`.

The two content sites share a **unified theme** (Claude warm-gray `#F8F8F6` + graphite `#5A5953`,
minimalist); this homepage keeps its own template style (no graphite accent).

## Asset rules (keep the repo lean)
- **Never commit large raw files.** Images → WebP (`cwebp -q 80-85 -resize 1280-1600 0`); videos → `ffmpeg -crf 30 -vf scale≤1280 -movflags +faststart`.
- Target: keep any committed asset well under ~9MB; future big videos → external host / Git LFS, not git history.
- The practical ceiling is the GitHub Pages **1GB built-site** limit.

## Naming & license
- Directories / files / slugs: **lowercase kebab-case** (`a-z 0-9 -`) — no spaces, uppercase, underscores, or CJK in paths (URL-friendly). CJK only in page titles/body.
- Licensed **MIT** (`LICENSE`) — fully open source; same for the two sibling repos.

## Gotchas
- `CNAME` currently says `jonbarron.info` (template leftover — not my domain). Site still serves at `yufengjin.github.io`; consider deleting `CNAME`.
- All internal links are **relative** — keep them that way so the site is domain-agnostic. (Exception: the footer links to the sibling sites use absolute same-domain paths `/paper-snapshots/` and `/learning-notes/`, since those are separate Pages sites.)
