# 论文海报流水线（pipeline）

这里只放**发布 + 重建索引**的确定性脚本。**进料（读取 inbox、识别论文、生成海报）由模型驱动的
`paper-notes` skill 负责**——它读取任意模态(PDF / 图片截图 / `.txt`·`.bib` 文献列表 / `queue.txt` /
直接粘贴的 id·url·标题),自己提取论文列表,对每篇派一个 **Sonnet 子代理**(遵循 `paper-poster` skill)
生成海报,然后调用下面的脚本发布。**不再有按文件类型的确定性路由。**

工作目录 `papers/_src/`(收件箱 + 原始图源)在项目内但**整目录 git-ignored**——仓库只存最终 WebP 海报。
默认 `POSTERS_SRC=papers/_src`,可用环境变量覆盖。

## 用法

```bash
# 1) 把任意来源丢进收件箱（PDF / 截图 / .bib / .txt …），或写进 queue.txt
cp some_paper.pdf papers/_src/_inbox/
echo "2410.24164" >> papers/_src/_inbox/queue.txt

# 2) 在 Claude 会话里触发 paper-notes skill（“处理 paper inbox / 生成 paper notes”）
#    → 它提取论文列表、派 Sonnet 子代理逐篇生成到 papers/_src/<slug>/，再自动跑下面的发布脚本

# 3) 发布脚本（paper-notes 会自动调用；也可手动跑）：图转 WebP、改写 <img src>、
#    拷 meta.json 进 papers/<slug>/，并重建 papers/index.html
papers/pipeline/publish_to_site.sh

# 4) 提交并推送，GitHub Pages 自动重新部署
git add papers && git commit -m "papers: add <slug>" && git push
```

## 组成（仅机械步骤，无 AI / 无路由）

| 文件 | 作用 |
|---|---|
| `publish_to_site.sh` | 把 `papers/_src/<slug>/` 的图转 WebP、改写 HTML 的 `<img src>`、拷 `meta.json` 进 `papers/<slug>/`，再调 `build_index.py` 重建 `papers/index.html`。幂等。 |
| `build_index.py` | 纯脚本,从所有 `<slug>/meta.json` 确定性重建 `index.html`(按大类分组 + 关键词标签过滤);`POSTERS_ROOT` 指定根目录。 |
| `backfill_meta.py` | 一次性历史工具:为缺 `meta.json` 的旧海报补写。 |

> 进料/编排不在脚本里——见 `.claude/skills/paper-notes/`(编排)与 `.claude/skills/paper-poster/`(单篇生成规范)。
> 去重按 arXiv id:`paper-notes` 生成前会 `grep` 合集里的 `meta.json`,已存在的跳过。

## meta.json 字段
`slug, title, arxiv_id, url, category, keywords[], summary_zh, date, source`
`category` = 4 大类之一(粗分组):`机器人 · Robotics ｜ 计算机视觉 · Computer Vision ｜ 生成模型 · Generative Models ｜ 理论与优化 · Theory & Optimization`。
细分主题靠 `keywords`(6–10 个),`build_index.py` 会把它们变成页面上的可点击标签过滤器。
