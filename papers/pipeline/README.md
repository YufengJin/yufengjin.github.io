# 论文海报自动化流水线（pipeline）

把论文丢进收件箱，跑一条命令，自动生成中文海报并更新合集首页。

**脚本是版本控制的唯一权威**，就放在仓库这里。**工作目录也在项目内** `papers/_src/`（收件箱 + 原始图源），
但**整目录 git-ignored、永不入库**——仓库只存最终的 WebP 海报。**零外部依赖**，从仓库任意位置直接跑即可；
想把工作目录换到别处就设 `POSTERS_SRC` 环境变量（默认 `papers/_src`）。

## 用法

```bash
# 方式 A：把 PDF 拖进收件箱（项目内）
cp some_paper.pdf papers/_src/_inbox/

# 方式 B：把 arXiv id / 链接 / 标题写进队列（一行一个）
echo "2410.24164" >> papers/_src/_inbox/queue.txt

# 1) 生成海报（headless Sonnet，按 paper-poster skill 产出到 papers/_src/<slug>/）
papers/pipeline/run_inbox.sh

# 2) 发布到仓库：图转 WebP、改写 <img src>、拷 meta.json，再重建 papers/index.html
papers/pipeline/publish_to_site.sh

# 3) 提交并推送，GitHub Pages 自动重新部署
git add papers && git commit -m "papers: add <slug>" && git push
```

工作目录换位置时设 `POSTERS_SRC`，例如：`POSTERS_SRC=/path/to/src papers/pipeline/run_inbox.sh`。
处理过的 PDF 移到 `papers/_src/_processed/`，队列行记入 `_processed/processed.tsv` 不会重复处理。

## 组成

| 文件 | 作用 |
|---|---|
| `run_inbox.sh` | 扫描 `papers/_src/_inbox/`，对每个新输入调用 `add_paper.sh`，去重、归档、最后重建源预览索引 |
| `add_paper.sh` | 对单篇论文跑 `claude -p`（Sonnet，受限工具），按 `paper-poster` skill 生成海报 + `meta.json` |
| `publish_to_site.sh` | 把 `papers/_src/` 源海报的图转 WebP、改写 HTML、拷 `meta.json` 进 `papers/<slug>/`，再重建 `papers/index.html` |
| `build_index.py` | 纯脚本，从所有 `<slug>/meta.json` 确定性重建 `index.html`（含按大类分组 + 关键词标签过滤）；`POSTERS_ROOT` 指定根目录 |
| `backfill_meta.py` | 一次性历史工具：为缺 `meta.json` 的旧海报补写 |

## meta.json 字段
`slug, title, arxiv_id, url, category, keywords[], summary_zh, date, source`
`category` = 4 大类之一（粗分组）：`机器人 · Robotics ｜ 计算机视觉 · Computer Vision ｜ 生成模型 · Generative Models ｜ 理论与优化 · Theory & Optimization`。
细分主题靠 `keywords`（6–10 个），`build_index.py` 会把它们变成页面上的可点击标签过滤器。

## 权限
`add_paper.sh` 用 `--allowedTools Bash Read Write WebFetch WebSearch`，并在仓库根目录（`cd "$SITE"`）下运行，
以加载 project + 全局 `CLAUDE.md` 和 `.claude/skills/`，不开全量 bypass。

## 可选：每天自动跑（launchd）
默认**手动**。想定时跑，创建 `~/Library/LaunchAgents/com.user.paperposter.plist`，
`ProgramArguments` 指向仓库里的 `papers/pipeline/run_inbox.sh`（默认工作目录即 `papers/_src`，无需额外配置；
要改位置才用 `EnvironmentVariables` 设 `POSTERS_SRC`），设 `StartCalendarInterval`（如每天 9:00），再 `launchctl load`。
