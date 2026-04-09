# voidpxL's blog

基于 `Hugo + PaperMod` 的个人技术博客，主要记录雷达感知、视觉算法、多传感器融合和工程实践相关内容。

## 项目结构

```text
.
├── archetypes/default.md          # 新文章模板
├── content/
│   ├── about.md                   # About 页面
│   ├── archives.md                # 归档页
│   ├── search.md                  # 搜索页
│   ├── posts/                     # 博文
│   └── series/_index.md           # 系列页
├── layouts/                       # 对主题的本地覆写
├── assets/css/extended/           # 扩展样式
├── static/                        # 静态资源
├── themes/PaperMod/               # 主题子模块
├── hugo.yaml                      # 站点配置
├── run_server.ps1                 # 本地预览
└── run_build.ps1                  # 生产构建
```

## 首次准备

先确保本机已经安装：

- `Hugo extended 0.145.0`
- `Git`

如果是新 clone 的仓库，记得把主题子模块拉下来：

```powershell
git clone --recursive <repo-url>
```

如果仓库已经 clone 过，但没有主题目录：

```powershell
git submodule update --init --recursive
```

## 本地运行

推荐直接用仓库自带脚本，不要手敲 `hugo server`。脚本已经处理了本地缓存目录，少踩权限坑。

启动本地预览：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_server.ps1
```

默认访问：

```text
http://localhost:1313/blog/
```

注意：

- 本地预览默认会包含 `draft: true` 的草稿文章
- 生产构建不会包含草稿

生产构建：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_build.ps1
```

构建结果输出到：

```text
public/
```

## 新写文章

### 1. 新建文章

推荐用 Hugo 命令生成文章，不要手搓 front matter。

```powershell
hugo new content posts/my-new-post/index.md
```

这会使用 [archetypes/default.md](/D:/my_web/blog/archetypes/default.md) 作为模板。

推荐使用 `page bundle` 方式组织文章，也就是一篇文章一个文件夹：

```text
content/posts/my-new-post/
├── index.md
└── image.png
```

这样图片、附件和文章可以放在一起。正文里直接这样引用：

```md
![示意图](image.png)
```

### 2. front matter 约定

默认模板里这些字段最常用：

```yaml
---
title: "文章标题"
summary: "一句话摘要"
date: 2026-04-09T10:00:00+08:00
draft: true
tags: []
categories: []
series: []
author: "lhz"
math: false
featured: false
showtoc: true
hideTitle: false
---
```

字段说明：

- `title`: 页面标题
- `summary`: 首页、列表页、搜索页会用到
- `draft`: `true` 表示草稿，本地可预览，生产构建不发布
- `tags`: 标签，适合细粒度关键词
- `categories`: 分类，适合较宽泛的栏目
- `series`: 系列，用于把连续文章组织到 `/series/`
- `featured`: 设为 `true` 后，会出现在首页“精选文章”
- `math`: 文章里有公式时设为 `true`
- `showtoc`: 是否显示目录
- `hideTitle`: 是否隐藏主题默认标题

### 3. 正文写作建议

默认建议：

- 不要在正文里再写一个 `# 一级标题`
- 直接从 `## 背景`、`## 核心内容` 这种二级标题开始写

原因：

- 主题会自动渲染页面标题
- 如果你正文里再写一个 `# 标题`，就容易出现“双标题”

如果某篇旧文章已经手写了一级标题，有两个选择：

1. 删掉正文里的 `# 标题`
2. 保留正文一级标题，同时把 `hideTitle: true`

### 4. 发布文章

文章写完后，把：

```yaml
draft: false
```

然后重新运行本地预览或构建即可。

## 系列、标签和分类怎么维护

### 系列

`series` 用来组织一组连续文章，比 `tags` 更强。

例如：

```yaml
series: ["雷达与视觉融合"]
```

效果：

- 会自动出现在 `/series/`
- 同系列文章会自动聚合到对应系列页
- 文章页底部会显示所属系列

适合放进 `series` 的内容：

- 连续更新的专题
- 同一个项目的多篇复盘
- 同一个技术方向的阶段性笔记

不建议：

- 把临时关键词塞进 `series`
- 一个系列名今天叫“雷视融合”，明天又叫“雷达视觉融合”

结论：系列名尽量固定，少而稳。

### 标签

`tags` 用来打细粒度关键词，例如：

```yaml
tags: ["Camera", "Fusion", "nuScenes"]
```

原则：

- 标签描述“这篇文章涉及了什么”
- 系列描述“这篇文章属于哪条连续主线”

建议控制标签数量，不要一篇文章打十几个标签。

### 分类

`categories` 用来放宽泛栏目，比如：

```yaml
categories: ["Tutorials"]
```

这个站目前分类使用得比较轻，重点还是 `series + tags`。

## 首页精选怎么维护

想让某篇文章出现在首页精选区，直接在 front matter 里加：

```yaml
featured: true
```

现在首页精选适合放：

- 最能代表博客方向的文章
- 完整度较高的文章
- 想优先给访客看的文章

不建议把所有文章都设成精选，不然这个模块就失去意义了。

## 推荐写作流程

1. 新建文章

```powershell
hugo new content posts/my-new-post/index.md
```

2. 填好 `title / summary / tags / series`
3. 在正文里直接从二级标题开始写
4. 本地预览检查页面效果
5. 写完后改 `draft: false`
6. 运行生产构建确认无误

## 部署说明

仓库已经带了 GitHub Pages 工作流：[hugo.yaml](/D:/my_web/blog/.github/workflows/hugo.yaml)

默认逻辑：

- push 到 `main`、`master` 或 `gh-pages` 会触发构建
- 构建产物来自 `public/`
- GitHub Pages 的来源需要设置为 `GitHub Actions`

如果线上页面异常，先检查两件事：

1. Actions 工作流是否成功
2. Pages 来源是不是 `GitHub Actions`

## 维护时最常改的文件

- [hugo.yaml](/D:/my_web/blog/hugo.yaml): 站点菜单、主题参数、taxonomy、SEO
- [default.md](/D:/my_web/blog/archetypes/default.md): 新文章模板
- [single.html](/D:/my_web/blog/layouts/_default/single.html): 单篇文章页覆写
- [list.html](/D:/my_web/blog/layouts/_default/list.html): 首页和列表页覆写
- [home_featured.html](/D:/my_web/blog/layouts/partials/home_featured.html): 首页精选模块
- [blog-custom.css](/D:/my_web/blog/assets/css/extended/blog-custom.css): 博客扩展样式

## 备注

站点里已经有一篇示例文章模板：

- [template.md](/D:/my_web/blog/content/posts/template.md)

但真正生成新文章时，优先以 `archetypes/default.md` 为准。
