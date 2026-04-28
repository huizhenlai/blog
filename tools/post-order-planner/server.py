from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parents[2]
POSTS_ROOT = REPO_ROOT / "content" / "posts"
STATIC_ROOT = Path(__file__).resolve().parent
FRONT_MATTER_RE = re.compile(r"\A---(?P<nl>\r?\n)(?P<front>.*?)(?P<front_nl>\r?\n)---(?P<after>\r?\n?)", re.S)


def post_files() -> list[Path]:
    root_markdown = list(POSTS_ROOT.glob("*.md"))
    bundle_markdown = list(POSTS_ROOT.rglob("index.md"))
    return sorted({path.resolve() for path in root_markdown + bundle_markdown})


def front_matter_match(content: str) -> re.Match[str]:
    match = FRONT_MATTER_RE.match(content)
    if not match:
        raise ValueError("missing front matter")
    return match


def front_scalar(front_matter: str, name: str) -> str | None:
    match = re.search(rf"(?m)^\s*{re.escape(name)}\s*:\s*(.+?)\s*(?:#.*)?$", front_matter)
    return match.group(1).strip() if match else None


def yaml_scalar(value: str | None) -> str:
    if not value:
        return ""
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value


def yaml_array(value: str | None) -> list[str]:
    if not value:
        return []
    value = value.strip()
    if not (value.startswith("[") and value.endswith("]")):
        return []
    inner = value[1:-1].strip()
    if not inner:
        return []
    return [yaml_scalar(item) for item in inner.split(",") if yaml_scalar(item)]


def parse_date(raw: str) -> datetime | None:
    if not raw:
        return None
    candidate = raw.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(candidate)
    except ValueError:
        try:
            return datetime.strptime(candidate, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        except ValueError:
            return None


def read_post_record(path: Path) -> dict[str, Any]:
    content = path.read_text(encoding="utf-8")
    match = front_matter_match(content)
    front = match.group("front")

    weight_raw = yaml_scalar(front_scalar(front, "weight"))
    try:
        weight = int(weight_raw) if weight_raw else 0
    except ValueError:
        weight = 0

    date_raw = yaml_scalar(front_scalar(front, "date"))
    date_value = parse_date(date_raw)

    return {
        "id": path.relative_to(REPO_ROOT).as_posix(),
        "path": path.relative_to(REPO_ROOT).as_posix(),
        "title": yaml_scalar(front_scalar(front, "title")) or path.stem,
        "weight": weight,
        "date": date_value.strftime("%Y-%m-%d") if date_value else "",
        "draft": yaml_scalar(front_scalar(front, "draft")) == "true",
        "featured": yaml_scalar(front_scalar(front, "featured")) == "true",
        "series": yaml_array(front_scalar(front, "series")),
        "tags": yaml_array(front_scalar(front, "tags")),
    }


def sorted_posts() -> list[dict[str, Any]]:
    posts = [read_post_record(path) for path in post_files()]

    def sort_key(post: dict[str, Any]) -> tuple[Any, ...]:
        date_value = parse_date(post["date"])
        timestamp = date_value.timestamp() if date_value else float("-inf")
        return (
            0 if post["weight"] > 0 else 1,
            post["weight"] if post["weight"] > 0 else 2**31 - 1,
            -timestamp,
            post["title"].lower(),
        )

    return sorted(posts, key=sort_key)


def taxonomy_summary() -> dict[str, Any]:
    posts = sorted_posts()
    tag_counts: dict[str, int] = {}
    series_counts: dict[str, int] = {}

    for post in posts:
        for tag in post["tags"]:
            tag_counts[tag] = tag_counts.get(tag, 0) + 1
        for series_name in post["series"]:
            series_counts[series_name] = series_counts.get(series_name, 0) + 1

    def to_count_list(source: dict[str, int]) -> list[dict[str, Any]]:
        return [
            {"name": name, "count": count}
            for name, count in sorted(source.items(), key=lambda item: (-item[1], item[0].lower()))
        ]

    return {
        "posts": posts,
        "stats": {
            "totalPosts": len(posts),
            "totalFeatured": sum(1 for post in posts if post["featured"]),
            "totalDrafts": sum(1 for post in posts if post["draft"]),
            "tagCount": len(tag_counts),
            "seriesCount": len(series_counts),
        },
        "taxonomies": {
            "tags": to_count_list(tag_counts),
            "series": to_count_list(series_counts),
        },
    }


def rewrite_weight(content: str, weight: int) -> str:
    match = front_matter_match(content)
    newline = "\r\n" if "\r\n" in content else "\n"
    front = match.group("front")
    after = match.group("after")
    rest = content[match.end() :]

    lines = front.splitlines()
    updated = False

    for index, line in enumerate(lines):
        if re.match(r"^\s*weight\s*:", line):
            lines[index] = f"weight: {weight}"
            updated = True
            break

    if not updated:
        insert_at = len(lines)
        for index, line in enumerate(lines):
            if re.match(r"^\s*draft\s*:", line):
                insert_at = index + 1
                break
            if insert_at == len(lines) and re.match(r"^\s*date\s*:", line):
                insert_at = index + 1
        lines.insert(insert_at, f"weight: {weight}")

    new_front = newline.join(lines)
    return f"---{newline}{new_front}{newline}---{after}{rest}"


def save_post_order(ordered_ids: list[str]) -> dict[str, Any]:
    posts = sorted_posts()
    all_ids = sorted(post["id"] for post in posts)
    if len(ordered_ids) != len(posts):
      raise ValueError("Save failed: post count mismatch.")
    if sorted(set(ordered_ids)) != all_ids:
      raise ValueError("Save failed: ordered ids do not match repository posts.")

    changed = 0
    for index, post_id in enumerate(ordered_ids, start=1):
        path = REPO_ROOT / Path(post_id)
        content = path.read_text(encoding="utf-8")
        updated = rewrite_weight(content, index)
        if updated != content:
            path.write_text(updated, encoding="utf-8", newline="")
            changed += 1

    return {"changed": changed, "total": len(ordered_ids)}


class PlannerHandler(BaseHTTPRequestHandler):
    server_version = "PostOrderPlanner/1.0"

    def log_message(self, format: str, *args: Any) -> None:
        return

    def do_GET(self) -> None:
        if self.path == "/api/summary":
            self.respond_json(taxonomy_summary())
            return
        self.serve_static()

    def do_POST(self) -> None:
        if self.path != "/api/reorder":
            self.respond_text("Method Not Allowed", status=HTTPStatus.METHOD_NOT_ALLOWED)
            return

        try:
            body = self.rfile.read(int(self.headers.get("Content-Length", "0"))).decode("utf-8")
            payload = json.loads(body or "{}")
            ordered_ids = payload.get("ids")
            if not isinstance(ordered_ids, list) or not ordered_ids:
                raise ValueError("Request is missing ids.")

            result = save_post_order([str(item) for item in ordered_ids])
            self.respond_json({
                "ok": True,
                "changed": result["changed"],
                "total": result["total"],
                "summary": taxonomy_summary(),
            })
        except Exception as exc:  # noqa: BLE001
            self.respond_json({"ok": False, "error": str(exc)}, status=HTTPStatus.INTERNAL_SERVER_ERROR)

    def serve_static(self) -> None:
        requested = "/" if self.path == "" else self.path
        relative = "index.html" if requested == "/" else unquote(requested.lstrip("/"))
        target = (STATIC_ROOT / relative).resolve()

        if not str(target).startswith(str(STATIC_ROOT.resolve())):
            self.respond_text("Forbidden", status=HTTPStatus.FORBIDDEN)
            return
        if not target.is_file():
            self.respond_text("Not Found", status=HTTPStatus.NOT_FOUND)
            return

        suffix = target.suffix.lower()
        content_type = {
            ".html": "text/html; charset=utf-8",
            ".css": "text/css; charset=utf-8",
            ".js": "application/javascript; charset=utf-8",
        }.get(suffix, "application/octet-stream")

        body = target.read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def respond_json(self, payload: Any, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def respond_text(self, text: str, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def run_self_test() -> None:
    summary = taxonomy_summary()
    if not summary["posts"]:
        raise SystemExit("No posts found.")

    sample = """---
title: "sample"
date: 2026-01-01
draft: true
---

body
"""
    rewritten = rewrite_weight(sample, 7)
    if not re.search(r"(?m)^weight:\s+7$", rewritten):
        raise SystemExit("Weight rewrite test failed.")

    print(
        f"SelfTest OK - posts: {summary['stats']['totalPosts']}, "
        f"tags: {summary['stats']['tagCount']}, "
        f"series: {summary['stats']['seriesCount']}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8756)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        run_self_test()
        return

    server = ThreadingHTTPServer(("127.0.0.1", args.port), PlannerHandler)
    print()
    print("Post Order Planner is running.")
    print(f"Open in browser: http://127.0.0.1:{args.port}/")
    print("Press Ctrl+C to stop.")
    print()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
