# 文章排序与 Taxonomy 规划器

本工具用于本地查看：

- 当前所有文章
- 每篇文章的 `weight`
- 当前已有的 `tags`
- 当前已有的 `series`

同时支持拖拽排序，并批量写回文章 front matter 中的 `weight`。

## 启动

在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\post-order-planner\run_post_order_planner.ps1
```

然后在浏览器打开：

```text
http://localhost:8756/
```

## 当前行为

- 会扫描 `content/posts/*.md`
- 也会扫描 `content/posts/**/index.md`
- 保存时会把当前顺序连续写回成 `weight: 1..N`
- taxonomy 统计只做读取，不会自动改 `tags` 或 `series`

## 备注

- 搜索或隐藏草稿时会禁用拖拽
- 这是本地管理工具，不会自动发布到线上
