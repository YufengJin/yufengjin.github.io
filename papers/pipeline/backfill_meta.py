#!/usr/bin/env python3
"""One-time: write meta.json for existing posters that lack one.

Sources, in priority order:
  - category / keywords / summary_zh from /tmp/kw.json (the keyword workflow output) if present
  - title + arXiv id/url parsed from the poster's index.html
  - keywords fallback: the <meta name="keywords"> already in the poster
Date defaults to 2026-06-10 (when the collection was assembled).
"""
import json, re, html, os, glob, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATE = "2026-06-10"

kw = {}
if os.path.exists("/tmp/kw.json"):
    for r in json.load(open("/tmp/kw.json"))["result"]:
        kw[r["slug"]] = r

def parse_poster(slug):
    p = os.path.join(ROOT, slug, "index.html")
    x = open(p, encoding="utf-8").read()
    t = re.search(r"<title>(.*?)</title>", x, re.S)
    title = html.unescape(re.sub(r"\s+", " ", t.group(1)).strip()) if t else slug
    aid = re.search(r"arxiv\.org/(?:abs|html|pdf)/(\d{4}\.\d{4,5})", x)
    aid = aid.group(1) if aid else ""
    # canonical url: arxiv abs, else first external link in the page
    if aid:
        url = f"https://arxiv.org/abs/{aid}"
    else:
        u = re.search(r'href="(https?://(?!arxiv\.org/(?:html|pdf))[^"]+)"', x)
        url = u.group(1) if u else ""
    mk = re.search(r'name="keywords"\s+content="([^"]*)"', x)
    meta_kws = [k.strip() for k in mk.group(1).split(",")] if mk else []
    return title, aid, url, meta_kws

def main():
    made = 0; skipped = 0
    for d in sorted(glob.glob(os.path.join(ROOT, "*"))):
        slug = os.path.basename(d)
        if slug.startswith("_") or slug == "bin":
            continue
        if not os.path.exists(os.path.join(d, "index.html")):
            continue
        mp = os.path.join(d, "meta.json")
        if os.path.exists(mp):
            skipped += 1; continue
        title, aid, url, meta_kws = parse_poster(slug)
        r = kw.get(slug, {})
        meta = {
            "slug": slug,
            "title": title,
            "arxiv_id": aid,
            "url": url,
            "category": r.get("category", "未分类"),
            "keywords": r.get("keywords") or meta_kws,
            "summary_zh": r.get("summary_zh", ""),
            "date": DATE,
            "source": "backfill",
        }
        json.dump(meta, open(mp, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        made += 1
    print(f"meta.json written: {made}, already-present: {skipped}")

if __name__ == "__main__":
    main()
