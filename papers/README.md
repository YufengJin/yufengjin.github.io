# Paper Notes — 维护说明

本目录是 **Paper Notes**：我读过论文的中文图文海报合集。每个 `papers/<slug>/` 含
`index.html`（中文正文 + WebP 图）+ `img/*.webp` + `meta.json`。落地页 `papers/index.html`
是**生成的**，不要手改。

> 生成与发布的工具链在仓库**之外**（私有、体积大）：`~/Downloads/papers/posters/`。
> 本仓库只存最终产物（WebP 海报）。本文件是仓库内的速查；更详细的流水线说明见根目录 `CLAUDE.md`。

## 每日更新一篇（end to end）

```bash
# 1) 把论文加入收件箱（三选一）
echo "<arxiv-id|url|title>" >> ~/Downloads/papers/posters/_inbox/queue.txt   # 写队列，一行一个
#   或：cp some_paper.pdf ~/Downloads/papers/posters/_inbox/                  # 直接拖 PDF 进收件箱

# 2) 生成海报（Sonnet via `claude -p`，按 paper-poster skill 产出 index.html + img + meta.json）
~/Downloads/papers/posters/bin/run_inbox.sh

# 3) 发布到本仓库：图转 WebP、改写 <img src>、拷贝 <slug>/，再重建 papers/index.html
~/Downloads/papers/posters/bin/publish_to_site.sh

# 4) 提交并推送，GitHub Pages 自动重新部署
git add papers && git commit -m "papers: add <slug>" && git push
```

- `queue.txt`：以 `#` 开头的行被忽略；已处理过的行记入 `_processed/processed.tsv`，**不会重复处理**。
- 处理完的 PDF 会移到 `_processed/`。

## 注意事项

- **落地页别手改**：`papers/index.html` 由 `bin/build_index.py` 从各 `meta.json` 确定性重建，
  `meta.json` 是每篇海报的唯一数据源。要改标题/分类/关键词，去改对应的 `meta.json` 再重建。
- **分类是「大类」，四选一**（`meta.json` 的 `category`，写错就不进对应分组）。大类只做**粗分组**，
  细分主题靠 `keywords` 区分（生成器会把关键词变成页面上的可点击标签过滤器）：
  - `机器人 · Robotics`
  - `计算机视觉 · Computer Vision`
  - `生成模型 · Generative Models`
  - `理论与优化 · Theory & Optimization`
- **标签过滤**：`papers/index.html` 顶部有高频标签栏，卡片上的 keyword chip 也可点击，点一下按该标签筛选、
  再点取消；搜索框（标题 / 关键词 / arXiv 号）与标签可叠加。关键词写得准，过滤才好用——所以每篇仍要 6–10 个 keywords。
- **内容规范**（paper-poster skill 强制）：正文中文，专业术语 / 指标 / 引文保留英文；
  所有数字逐字摘自论文，**不得编造**；每篇海报头部和底部都要有 arXiv / 来源链接；6–10 个关键词；
  章节固定为 动机 / 方法 / 实验 / 局限性。
- **资产只放 WebP，保持仓库精简**：海报图一律 WebP（`publish_to_site.sh` 会自动 `cwebp -q 80 -resize 1280 0` 转换并改写 HTML 里的 `.png/.jpg → .webp`）。
  **不要把原始大图 / PDF 提交进来**——源文件留在 `~/Downloads/papers/posters/`，永不入库。
- **链接保持相对路径**，让站点与域名无关。
- **发布脚本可重复跑**（idempotent）：图片已是最新就跳过；`meta.json` 一并拷贝。
- **可选定时**：流水线默认手动触发。想每天自动跑，用 launchd 指向 `run_inbox.sh`
  （`StartCalendarInterval`，如每天 9:00），同一套脚本无需改动。

## 容量

资产红线与容量估算（WebP/视频压缩参数、~9MB 单文件上限、GitHub Pages 1GB 构建上限）以根目录
`CLAUDE.md` 的「Asset rules」为准，这里不再重复。
