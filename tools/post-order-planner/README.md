# 文章排序规划器

本工具用于本地直观规划文章顺序，并批量写回 `content/posts` 下所有文章的 `weight`。

## 用法

在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\post-order-planner\run_post_order_planner.ps1
```

启动后，在浏览器打开：

```text
http://localhost:8756/
```

## 当前规则

- 列表显示所有文章，兼容 `content/posts/*.md` 和 `content/posts/**/index.md`
- 拖拽排序后，保存时会按当前顺序将 `weight` 连续重写为 `1..N`
- 首页精选仍由 `featured: true` 控制
- 首页精选展示顺序由 `featured: true` 文章中最小的 3 个 `weight` 决定

## 注意

- 搜索过滤状态下禁用拖拽，避免不可见项被误排
- 这是本地管理工具，不会自动发到线上
- 保存后建议重新运行 Hugo 构建确认排序效果
