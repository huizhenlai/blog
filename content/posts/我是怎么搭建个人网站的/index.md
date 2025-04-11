---
title: "我是怎么搭建自己的个人网站的"
summary: "目前对前端完全不懂, 基于开源资料和ChatGPT进行搭建, 效果基本也能够令我满意"
date: 2025-03-25
draft: false 
tags: [Hugo]  # 标签，可以是多个
categories: ["Tutorials"]  # 分类
author: "lhz"  # 作者
hideTitle: true
---

# 我是怎么搭建自己的个人网站的

## KaTex

与正常语法略有不同, 主要体现在矩阵的换行, 需要使用 `////` 四个反斜杠, 而非一般的两个

[Markdown 数学公式排版 KaTex 语法 - sinlov's blog](https://blog.sinlov.cn/posts/2023/03/16/markdown-数学公式排版-katex-语法/)



## Page Bundles

在blog中我有放图片的需求，但是本地的文章推到github action之后，图片的索引往往都会出现问题，经过研究发现了以下几个解决方案

1. 图床：把图片预先上传到图床网站上，在本地和云端都索引该路径。
2. 本地直接写成绝对路径（且必须是基于github源路径的）
3. 把所有图片直接放在post的目录下，和.md在一级。
4. Page Bundles

前者需要收到图床网站的限制，且每次在本地放图也需要上传图，麻烦。

次者在本地看不到图片，不利于排版和复习。

后者在本地太乱了，找不到东西。

而Page Bundles是Hugo推荐的做法，即 每篇文章放一个文件夹，Markdown 和图像放一起，组织成如下的格式。

```bash
content/
    ├── about
    │   ├── index.md
    ├── posts
    │   ├── my-post
    │   │   ├── content1.md
    │   │   ├── image1.jpg
    │   │   └── index.md
    │   └── my-other-post
    │       └── index.md
    └── another-section
        ├── ..
        └── not-a-leaf-bundle
            ├── ..
            └── another-leaf-bundle
                └── index.md
```

在站点上，路径显示的是文件夹的名字，而文档的名字需要取成index.md。
