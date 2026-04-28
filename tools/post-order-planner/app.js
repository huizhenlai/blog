const state = {
  posts: [],
  taxonomies: {
    tags: [],
    series: [],
  },
  stats: {
    totalPosts: 0,
    totalFeatured: 0,
    totalDrafts: 0,
    tagCount: 0,
    seriesCount: 0,
  },
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
  visibleCount: document.getElementById("visible-count"),
  empty: document.getElementById("empty-state"),
  dragHint: document.getElementById("drag-hint"),
  status: document.getElementById("status-bar"),
  dirty: document.getElementById("stat-dirty"),
  totalPosts: document.getElementById("stat-total-posts"),
  featuredPosts: document.getElementById("stat-featured-posts"),
  draftPosts: document.getElementById("stat-draft-posts"),
  totalTags: document.getElementById("stat-total-tags"),
  totalSeries: document.getElementById("stat-total-series"),
  tagCloud: document.getElementById("tag-cloud"),
  seriesCloud: document.getElementById("series-cloud"),
  tagCountPill: document.getElementById("tag-count-pill"),
  seriesCountPill: document.getElementById("series-count-pill"),
};

function setStatus(message, type = "") {
  elements.status.textContent = message;
  elements.status.className = `status-bar ${type}`.trim();
}

function markDirty(value) {
  state.dirty = value;
  elements.dirty.textContent = value ? "待保存" : "未修改";
}

function isFiltering() {
  return Boolean(elements.search.value.trim()) || elements.hideDrafts.checked;
}

function getSearchKeyword() {
  return elements.search.value.trim().toLowerCase();
}

function getVisiblePosts() {
  const keyword = getSearchKeyword();
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

function renderTaxonomyCloud(container, items, prefix = "") {
  container.innerHTML = "";

  items.forEach((item) => {
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = "taxonomy-chip";
    chip.innerHTML = `<span>${prefix}${item.name}</span><strong>${item.count}</strong>`;
    chip.addEventListener("click", () => {
      elements.search.value = item.name;
      render();
    });
    container.appendChild(chip);
  });
}

function updateStats() {
  elements.totalPosts.textContent = String(state.stats.totalPosts);
  elements.featuredPosts.textContent = String(state.stats.totalFeatured);
  elements.draftPosts.textContent = String(state.stats.totalDrafts);
  elements.totalTags.textContent = String(state.stats.tagCount);
  elements.totalSeries.textContent = String(state.stats.seriesCount);
  elements.tagCountPill.textContent = String(state.taxonomies.tags.length);
  elements.seriesCountPill.textContent = String(state.taxonomies.series.length);
  elements.visibleCount.textContent = `显示 ${getVisiblePosts().length} 篇`;
  elements.dragHint.textContent = isFiltering() ? "已禁用" : "已启用";
}

function renderTags(container, tags) {
  container.innerHTML = "";
  if (!tags || tags.length === 0) {
    container.textContent = "无 tags";
    return;
  }

  tags.slice(0, 4).forEach((tag) => {
    const chip = document.createElement("span");
    chip.className = "inline-chip";
    chip.textContent = `#${tag}`;
    container.appendChild(chip);
  });
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
    fragment.querySelector(".post-series").textContent = (post.series || []).join(" / ") || "无 series";
    fragment.querySelector(".post-path").textContent = post.path;

    fragment.querySelector(".featured-badge").hidden = !post.featured;
    fragment.querySelector(".draft-badge").hidden = !post.draft;
    renderTags(fragment.querySelector(".tag-row"), post.tags);

    item.addEventListener("dragstart", () => {
      state.dragId = post.id;
      item.classList.add("dragging");
    });

    item.addEventListener("dragend", () => {
      state.dragId = null;
      item.classList.remove("dragging", "drag-over");
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
  setStatus(`已调整排序: ${moved.title}`);
  render();
}

function applySummary(summary) {
  state.posts = summary.posts || [];
  state.taxonomies = summary.taxonomies || { tags: [], series: [] };
  state.stats = summary.stats || state.stats;
  markDirty(false);
  renderTaxonomyCloud(elements.tagCloud, state.taxonomies.tags, "#");
  renderTaxonomyCloud(elements.seriesCloud, state.taxonomies.series);
  render();
}

async function loadSummary() {
  setStatus("正在加载文章与 taxonomy 数据...");
  const response = await fetch("./api/summary");
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || "加载失败。");
  }

  applySummary(data);
  setStatus("已加载当前文章、tags 和 series。", "success");
}

async function saveOrder() {
  if (!state.dirty) {
    setStatus("当前没有需要保存的排序改动。");
    return;
  }

  elements.save.disabled = true;
  setStatus("正在写回 weight ...");

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

    applySummary(data.summary);
    setStatus(`保存完成，已写回 ${data.changed} 个文件。`, "success");
  } catch (error) {
    setStatus(error.message, "error");
  } finally {
    elements.save.disabled = false;
  }
}

elements.search.addEventListener("input", render);
elements.hideDrafts.addEventListener("change", render);
elements.reload.addEventListener("click", () => {
  loadSummary().catch((error) => setStatus(error.message, "error"));
});
elements.save.addEventListener("click", () => {
  saveOrder().catch((error) => setStatus(error.message, "error"));
});

window.addEventListener("beforeunload", (event) => {
  if (!state.dirty) {
    return;
  }
  event.preventDefault();
  event.returnValue = "";
});

loadSummary().catch((error) => setStatus(error.message, "error"));
