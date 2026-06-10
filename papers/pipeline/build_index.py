#!/usr/bin/env python3
"""Rebuild posters/index.html deterministically from every <slug>/meta.json sidecar.

Single source of truth for the collection landing page. No AI, no network.
Run after adding/removing posters:  python3 bin/build_index.py

Taxonomy = 4 broad buckets (大类). Fine-grained distinctions are expressed by
each poster's `keywords` and are filterable as clickable tags on the page.
"""
import json, glob, html, os, sys
from collections import Counter

ROOT = os.environ.get("POSTERS_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # posters/

# Broad taxonomy (order = display order). Must match SKILL.md.细分用 keyword/tag。
CATS = [
    "机器人 · Robotics",
    "计算机视觉 · Computer Vision",
    "生成模型 · Generative Models",
    "理论与优化 · Theory & Optimization",
]

# How many high-frequency tags to surface in the top tag bar.
TAGBAR_MAX = 28
TAGBAR_MIN_COUNT = 2  # only show a tag in the bar if it appears on >= this many posters

def load_metas():
    metas = []
    for p in glob.glob(os.path.join(ROOT, "*", "meta.json")):
        try:
            m = json.load(open(p, encoding="utf-8"))
        except Exception as e:
            print(f"  ! skip {p}: {e}", file=sys.stderr); continue
        m.setdefault("slug", os.path.basename(os.path.dirname(p)))
        # only include if the poster page actually exists
        if os.path.exists(os.path.join(ROOT, m["slug"], "index.html")):
            metas.append(m)
    return metas

def card(m):
    slug = m["slug"]
    title = html.escape(m.get("title", slug))
    summ = html.escape(m.get("summary_zh", ""))
    if len(summ) > 120:
        summ = summ[:118] + "…"
    allkws = m.get("keywords") or []
    chips = "".join(
        f'<span data-tag="{html.escape(k)}">{html.escape(k)}</span>' for k in allkws[:5]
    )
    # all keywords (lowercased, pipe-delimited) so tag filtering works even for hidden ones
    datakw = html.escape("|".join(k.lower() for k in allkws))
    date = html.escape(m.get("date", ""))
    aid = m.get("arxiv_id", "")
    url = m.get("url", "")
    if aid:
        badge = f'<span class="ax">arXiv:{html.escape(aid)}</span>'
    elif url:
        badge = '<span class="ax noax">原文</span>'
    else:
        badge = ""
    return (f'  <a class="card" data-kw="{datakw}" href="{slug}/index.html">'
            f'<div class="date">{date}</div>'
            f'<div class="t">{title}</div>'
            f'<div class="s">{summ}</div>'
            f'<div class="kw">{chips}</div>'
            f'{badge}</a>\n')

def build():
    metas = load_metas()
    bycat = {c: [] for c in CATS}
    extra = "未分类"
    for m in metas:
        bycat.setdefault(m.get("category", extra), []).append(m)
    order = CATS + [c for c in bycat if c not in CATS]

    sec = ""
    n = 0
    for c in order:
        items = bycat.get(c, [])
        if not items:
            continue
        # newest first by date, then title for stable ties
        items.sort(key=lambda m: (m.get("date", ""), m.get("title", "")), reverse=True)
        sec += f'<h2>{html.escape(c)} <span class="gc">{len(items)}</span></h2>\n<div class="grid">\n'
        for m in items:
            sec += card(m); n += 1
        sec += "</div>\n"

    # top tag bar: most common keywords across the whole collection (case-insensitive,
    # keeping the first-seen original casing for display)
    cnt = Counter()
    disp = {}
    for m in metas:
        for k in (m.get("keywords") or []):
            lk = k.lower()
            cnt[lk] += 1
            disp.setdefault(lk, k)
    top = [(lk, c) for lk, c in cnt.most_common() if c >= TAGBAR_MIN_COUNT][:TAGBAR_MAX]
    tagbar = "".join(
        f'<span class="tag" data-tag="{html.escape(disp[lk])}">{html.escape(disp[lk])}<b>{c}</b></span>'
        for lk, c in top
    )

    page = f'''<!DOCTYPE html>
<html lang="zh"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>论文海报合集</title>
<meta name="description" content="AI / 机器人 / 三维视觉 论文中文图文海报合集，每篇含动机·方法·实验·局限性。">
<style>
 body{{margin:0;background:#0b0e13;color:#e6edf3;line-height:1.6;font-family:-apple-system,"PingFang SC","Microsoft YaHei","Segoe UI",Roboto,sans-serif}}
 .wrap{{max-width:1180px;margin:0 auto;padding:58px 22px 80px}}
 h1{{font-size:33px;margin:0 0 8px}}
 .intro{{color:#9aa7b4;font-size:16.5px;margin:0 0 4px}}
 .count{{color:#6ea8fe;font-size:14px;margin-bottom:8px}}
 .search{{width:100%;max-width:420px;margin:14px 0 4px;padding:10px 14px;border-radius:10px;border:1px solid #283040;background:#11151b;color:#e6edf3;font-size:14px}}
 .tags{{display:flex;flex-wrap:wrap;gap:7px;margin:12px 0 2px;align-items:center}}
 .tags .lbl{{font-size:12px;color:#5c6773;margin-right:2px}}
 .tag{{cursor:pointer;font-size:12px;color:#9aa7b4;background:#11151b;border:1px solid #283040;border-radius:999px;padding:3px 11px;user-select:none;transition:.14s}}
 .tag:hover{{border-color:#6ea8fe;color:#cdd9e5}}
 .tag.on{{background:#16243a;border-color:#6ea8fe;color:#cfe3ff}}
 .tag b{{color:#5c6773;font-weight:400;margin-left:5px;font-size:11px}}
 .tag.on b{{color:#6ea8fe}}
 .active{{margin:10px 0 2px;font-size:13px;color:#9aa7b4}}
 .active b{{color:#cfe3ff;font-weight:600}}
 .active .clr{{cursor:pointer;color:#ffb454;margin-left:10px;border:1px solid #3a2e16;background:#251c10;border-radius:6px;padding:1px 9px;font-size:12px}}
 h2{{font-size:19px;margin:34px 0 14px;padding-left:12px;border-left:3px solid #6ea8fe;color:#cdd9e5;display:flex;align-items:center;gap:10px}}
 .gc{{font-size:12px;color:#9aa7b4;background:#161b22;border:1px solid #283040;border-radius:999px;padding:1px 9px}}
 .grid{{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}}
 @media(max-width:900px){{.grid{{grid-template-columns:1fr 1fr}}}} @media(max-width:600px){{.grid{{grid-template-columns:1fr}}}}
 a.card{{display:flex;flex-direction:column;text-decoration:none;color:inherit;border:1px solid #283040;border-radius:13px;padding:15px 17px;background:linear-gradient(180deg,#161b22,#11151b);transition:.16s}}
 a.card:hover{{transform:translateY(-3px);border-color:#6ea8fe}}
 .date{{font-size:11px;color:#5c6773;font-family:ui-monospace,monospace;margin-bottom:6px}}
 .t{{font-size:15px;font-weight:700;margin-bottom:7px;color:#eaf1f8;line-height:1.35}}
 .s{{color:#9aa7b4;font-size:12.5px;flex:1;margin-bottom:9px}}
 .kw{{display:flex;flex-wrap:wrap;gap:5px;margin-bottom:10px}}
 .kw span{{font-size:11px;color:#7d8a97;background:#141a22;border:1px solid #222b36;border-radius:6px;padding:1px 7px;cursor:pointer;transition:.14s}}
 .kw span:hover{{color:#cfe3ff;border-color:#6ea8fe}}
 .ax{{align-self:flex-start;font-size:11.5px;color:#7ee787;background:#16241a;border:1px solid #24402c;border-radius:6px;padding:2px 8px;font-family:ui-monospace,monospace}}
 .ax.noax{{color:#ffb454;background:#251c10;border-color:#3a2e16}}
 footer{{color:#5c6773;font-size:13px;margin-top:46px;text-align:center}}
 .hide{{display:none!important}}
</style></head><body><div class="wrap">
<h1>论文海报合集</h1>
<p class="intro">每篇一页图文海报，含 动机 / 方法 / 实验 / 局限性 四节，配论文真实插图，页眉页脚均链原文。</p>
<p class="count">共 {n} 篇 · 每日新增</p>
<input class="search" id="q" placeholder="🔍 搜索标题 / 关键词 / arXiv 号…" oninput="render()">
<div class="tags"><span class="lbl">标签：</span>{tagbar}</div>
<div class="active hide" id="active">已筛选标签：<b id="activeLbl"></b><span class="clr" onclick="clearTag()">清除 ✕</span></div>
{sec}
<footer>由各论文 arXiv HTML / PDF 源与插图整理生成 · 数值均引自原文 · 仅供学习参考</footer>
</div>
<script>
var active="";  // active tag, lowercased; "" = none
function render(){{
 var q=document.getElementById('q').value.toLowerCase();
 document.querySelectorAll('a.card').forEach(function(c){{
  var okq=!q||c.textContent.toLowerCase().indexOf(q)>=0;
  var okt=!active||('|'+(c.dataset.kw||'')+'|').indexOf('|'+active+'|')>=0;
  c.classList.toggle('hide',!(okq&&okt));}});
 document.querySelectorAll('h2').forEach(function(h){{
  var g=h.nextElementSibling, any=g&&g.querySelector('a.card:not(.hide)');
  h.classList.toggle('hide',!any); if(g) g.classList.toggle('hide',!any);}});
 document.querySelectorAll('.tag').forEach(function(p){{
  p.classList.toggle('on',(p.dataset.tag||'').toLowerCase()===active);}});
 var b=document.getElementById('active');
 b.classList.toggle('hide',!active);
 document.getElementById('activeLbl').textContent=active;
}}
function toggleTag(t){{var lt=(t||'').toLowerCase(); active=(active===lt)?"":lt; render();}}
function clearTag(){{active=""; render();}}
document.addEventListener('click',function(e){{
 var el=e.target.closest('[data-tag]');
 if(el){{e.preventDefault(); e.stopPropagation(); toggleTag(el.getAttribute('data-tag'));}}
}});
</script>
</body></html>'''
    out = os.path.join(ROOT, "index.html")
    with open(out, "w", encoding="utf-8") as f:
        f.write(page)
    print(f"wrote {out} · {n} posters across {sum(1 for c in order if bycat.get(c))} categories")

if __name__ == "__main__":
    build()
