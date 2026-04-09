const state = {
  posts: [],
  initialOrder: [],
  dragId: null,
  dirty: false,
};

const elements = {
  list: document.getElementById("post-list"),
  template: document.getElementById("post-item-template"),
  search: document.getElementById("search-input"),
  hideDrafts: document.getElementById("hide-drafts"),
  reload: document.getElementById("reload-btn"),
  save: document.getElementById("save-btn"),
  total: document.getElementById("stat-total"),
  featured: document.getElementById("stat-featured"),
  drafts: document.getElementById("stat-drafts"),
  dirty: document.getElementById("stat-dirty"),
  status: document.getElementById("status-bar"),
  visibleCount: document.getElementById("visible-count"),
  dragHint: document.getElementById("drag-hint"),
  empty: document.getElementById("empty-state"),
};

function setStatus(message, type = "") {
  elements.status.textContent = message;
  elements.status.className = `status-bar ${type}`.trim();
}

function isFiltering() {
  return Boolean(elements.search.value.trim()) || elements.hideDrafts.checked;
}

function markDirty(nextValue) {
  state.dirty = nextValue;
  elements.dirty.textContent = nextValue ? "待保存" : "未修改";
}

function getVisiblePosts() {
  const keyword = elements.search.value.trim().toLowerCase();
  const hideDrafts = elements.hideDrafts.checked;

  return state.posts.filter((post) => {
    if (hideDrafts && post.draft) {
      return false;
    }

    if (!keyword) {
      return true;
    }

    const haystack = [
      post.title,
      post.path,
      ...(post.series || []),
      ...(post.tags || []),
    ]
      .join(" ")
      .toLowerCase();

    return haystack.includes(keyword);
  });
}

function updateStats() {
  elements.total.textContent = String(state.posts.length);
  elements.featured.textContent = String(state.posts.filter((post) => post.featured).length);
  elements.drafts.textContent = String(state.posts.filter((post) => post.draft).length);
  elements.visibleCount.textContent = `显示 ${getVisiblePosts().length} 篇`;
  elements.dragHint.textContent = isFiltering() ? "搜索状态下禁用拖拽" : "拖拽已启用";
}

function render() {
  const visiblePosts = getVisiblePosts();
  elements.list.innerHTML = "";
  elements.empty.hidden = visiblePosts.length > 0;

  visiblePosts.forEach((post) => {
    const fragment = elements.template.content.cloneNode(true);
    const item = fragment.querySelector(".post-item");
    const handle = fragment.querySelector(".drag-handle");
    const weight = state.posts.findIndex((candidate) => candidate.id === post.id) + 1;

    item.dataset.id = post.id;
    item.draggable = !isFiltering();
    handle.textContent = isFiltering() ? "锁定" : "⋮⋮";

    fragment.querySelector(".weight-badge").textContent = `weight ${weight}`;
    fragment.querySelector(".post-title").textContent = post.title;
    fragment.querySelector(".post-date").textContent = post.date || "无日期";
    fragment.querySelector(".post-series").textContent = (post.series || []).slice(0, 2).join(" / ") || "无系列";
    fragment.querySelector(".post-path").textContent = post.path;

    const featuredBadge = fragment.querySelector(".featured-badge");
    featuredBadge.hidden = !post.featured;

    const draftBadge = fragment.querySelector(".draft-badge");
    draftBadge.hidden = !post.draft;

    item.addEventListener("dragstart", () => {
      state.dragId = post.id;
      item.classList.add("dragging");
    });

    item.addEventListener("dragend", () => {
      state.dragId = null;
      item.classList.remove("dragging");
      item.classList.remove("drag-over");
    });

    item.addEventListener("dragover", (event) => {
      if (isFiltering()) {
        return;
      }
      event.preventDefault();
      item.classList.add("drag-over");
    });

    item.addEventListener("dragleave", () => {
      item.classList.remove("drag-over");
    });

    item.addEventListener("drop", (event) => {
      if (isFiltering()) {
        return;
      }
      event.preventDefault();
      item.classList.remove("drag-over");
      movePost(state.dragId, post.id);
    });

    elements.list.appendChild(fragment);
  });

  updateStats();
}

function movePost(fromId, toId) {
  if (!fromId || !toId || fromId === toId) {
    return;
  }

  const fromIndex = state.posts.findIndex((post) => post.id === fromId);
  const toIndex = state.posts.findIndex((post) => post.id === toId);
  if (fromIndex < 0 || toIndex < 0) {
    return;
  }

  const [moved] = state.posts.splice(fromIndex, 1);
  state.posts.splice(toIndex, 0, moved);
  markDirty(true);
  setStatus(`已调整排序：${moved.title}`, "");
  render();
}

async function loadPosts() {
  setStatus("正在加载文章列表...");
  const response = await fetch("./api/posts");
  if (!response.ok) {
    throw new Error("加载文章列表失败。");
  }

  const data = await response.json();
  state.posts = data.posts || [];
  state.initialOrder = state.posts.map((post) => post.id);
  markDirty(false);
  setStatus("文章列表已加载。", "success");
  render();
}

async function savePosts() {
  if (!state.dirty) {
    setStatus("当前没有需要保存的改动。");
    return;
  }

  elements.save.disabled = true;
  setStatus("正在保存排序...");

  try {
    const response = await fetch("./api/reorder", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ids: state.posts.map((post) => post.id),
      }),
    });

    const data = await response.json();
    if (!response.ok || !data.ok) {
      throw new Error(data.error || "保存失败。");
    }

    state.posts = data.posts || state.posts;
    state.initialOrder = state.posts.map((post) => post.id);
    markDirty(false);
    setStatus(`保存完成，已写回 ${data.changed} 个文件。`, "success");
    render();
  } catch (error) {
    setStatus(error.message, "error");
  } finally {
    elements.save.disabled = false;
  }
}

elements.search.addEventListener("input", () => {
  render();
});

elements.hideDrafts.addEventListener("change", () => {
  render();
});

elements.reload.addEventListener("click", async () => {
  try {
    await loadPosts();
  } catch (error) {
    setStatus(error.message, "error");
  }
});

elements.save.addEventListener("click", async () => {
  await savePosts();
});

window.addEventListener("beforeunload", (event) => {
  if (!state.dirty) {
    return;
  }
  event.preventDefault();
  event.returnValue = "";
});

loadPosts().catch((error) => {
  setStatus(error.message, "error");
});
