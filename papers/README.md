# Paper Notes — 维护说明

本目录是 **Paper Notes**：我读过论文的中文图文海报合集。每个 `papers/<slug>/` 含
`index.html`（中文正文 + WebP 图）+ `img/*.webp` + `meta.json`。落地页 `papers/index.html`
是**生成的**，不要手改。

> **进料是模型驱动的**（`paper-notes` skill），不是按文件类型写死的脚本。
> **工作目录在项目内** `papers/_src/`（收件箱 + 原始图源），但**整目录 git-ignored、永不入库**——
> 仓库只提交最终产物（`papers/<slug>/` 的 WebP 海报）。可用 `$POSTERS_SRC` 改到别处。零外部依赖。
> `papers/pipeline/` 只剩**发布 + 重建索引**两个机械脚本（详见 `pipeline/README.md`）。

## 更新流程（end to end）

```bash
# 1) 把任意来源丢进收件箱 papers/_src/_inbox/（不分类型：PDF / 截图 / .bib / .txt / queue.txt）
cp some_paper.pdf papers/_src/_inbox/
echo "<arxiv-id|url|title>" >> papers/_src/_inbox/queue.txt

# 2) 在 Claude 会话里触发 `paper-notes` skill（“处理 paper inbox / 生成 paper notes”）
#    → 它自己读取各模态、提取论文列表、对每篇派一个 Sonnet 子代理（按 paper-poster skill）生成到
#      papers/_src/<slug>/，去重后自动跑 publish_to_site.sh 重建 papers/index.html

# 3) 提交并推送，GitHub Pages 自动重新部署
git add papers && git commit -m "papers: add <slug>" && git push
```

- 收件箱接受任意模态；模型自行识别每个文件指向哪篇论文，无需按类型摆放。
- **按 arXiv id 去重**：`paper-notes` 生成前会 `grep` 合集里的 `meta.json`，已存在的跳过。
- 处理完的输入会移到 `papers/_src/_processed/`，不会重复处理。
- 只想生成单篇（不走收件箱）：直接用 `paper-poster` skill。

## 注意事项

- **落地页别手改**：`papers/index.html` 由 `pipeline/build_index.py` 从各 `meta.json` 确定性重建，
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
  **不要把原始大图 / PDF 提交进来**——源文件在 `papers/_src/`（git-ignored），永不入库。
- **链接保持相对路径**，让站点与域名无关。
- **发布脚本可重复跑**（idempotent）：图片已是最新就跳过；`meta.json` 一并拷贝。
- **单次只做被指派的那篇**：每个 Sonnet 子代理只处理分给它的一篇论文，不读收件箱、不顺手生成别篇
  （防止越权批量生成）。批量由 `paper-notes` 编排层统一派发。

## 容量

资产红线与容量估算（WebP/视频压缩参数、~9MB 单文件上限、GitHub Pages 1GB 构建上限）以根目录
`CLAUDE.md` 的「Asset rules」为准，这里不再重复。
