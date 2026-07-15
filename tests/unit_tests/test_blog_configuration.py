"""Validate repository conventions that should remain stable across builds."""

from pathlib import Path
import re


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
CANONICAL_SERIES = {
    "雷达与视觉融合",
    "标定与坐标系",
    "视觉几何与测速",
    "目标检测工程实践",
    "博客建设",
    "雷达感知笔记",
    "工具与工作流",
}


def read_text(relative_path: str) -> str:
    """Read a UTF-8 repository file.

    Args:
        relative_path: File path relative to the repository root.

    Returns:
        Decoded file content.
    """

    return (REPOSITORY_ROOT / relative_path).read_text(encoding="utf-8")


def extract_series(markdown: str) -> set[str]:
    """Extract series names from a simple YAML front matter array.

    Args:
        markdown: Markdown document including YAML front matter.

    Returns:
        Series names declared by the document.
    """

    match = re.search(r'^series:\s*\[(.*)]\s*$', markdown, re.MULTILINE)
    if match is None or not match.group(1).strip():
        return set()
    return {item.strip().strip('"\'') for item in match.group(1).split(",")}


def test_generated_directories_are_ignored() -> None:
    """Ensure reproducible Hugo outputs stay outside version control."""

    gitignore = read_text(".gitignore").splitlines()
    assert {"/public/", "/resources/", "/.hugo_cache/", "/.hugo_build.lock"} <= set(gitignore)


def test_math_is_loaded_per_article() -> None:
    """Ensure the global configuration does not force KaTeX onto every page."""

    configuration = read_text("hugo.yaml")
    assert re.search(r"^\s{2}math:\s*false\s*$", configuration, re.MULTILINE)


def test_pagination_contains_real_arrows() -> None:
    """Prevent the previous mojibake pagination characters from returning."""

    list_template = read_text("layouts/_default/list.html")
    assert "芦" not in list_template
    assert "禄" not in list_template
    assert "←&nbsp;" in list_template
    assert "&nbsp;→" in list_template


def test_posts_use_canonical_series() -> None:
    """Ensure posts do not silently create duplicate taxonomy branches."""

    post_files = list((REPOSITORY_ROOT / "content" / "posts").glob("*.md"))
    post_files.extend((REPOSITORY_ROOT / "content" / "posts").glob("*/index.md"))
    used_series = set().union(*(extract_series(path.read_text(encoding="utf-8")) for path in post_files))
    assert used_series <= CANONICAL_SERIES


def test_build_script_propagates_hugo_failures() -> None:
    """Ensure a failed Hugo process also fails the PowerShell build script."""

    build_script = read_text("run_build.ps1")
    assert "$hugoSucceeded = $?" in build_script
    assert "if (-not $hugoSucceeded)" in build_script
    assert "throw" in build_script
