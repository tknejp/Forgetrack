#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import os
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

DEFAULT_IGNORED_DIRS = {
    ".git",
    ".dart_tool",
    ".idea",
    ".vscode",
    "build",
    ".build",
    "dist",
    "node_modules",
    ".next",
    ".turbo",
    "coverage",
    ".gradle",
    ".venv",
    "venv",
    "__pycache__",
    "Pods",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
}

DEFAULT_IGNORED_FILES = {
    ".DS_Store",
}

TEXT_EXTENSIONS = {
    ".dart",
    ".kt",
    ".kts",
    ".java",
    ".gradle",
    ".yaml",
    ".yml",
    ".json",
    ".md",
    ".txt",
    ".xml",
    ".html",
    ".css",
    ".scss",
    ".js",
    ".ts",
    ".tsx",
    ".jsx",
    ".py",
    ".sh",
    ".bat",
    ".ps1",
    ".sql",
    ".arb",
    ".properties",
    ".swift",
    ".m",
    ".mm",
    ".c",
    ".cc",
    ".cpp",
    ".h",
    ".hpp",
}

COMMENT_PREFIXES_BY_EXT = {
    ".dart": ["//"],
    ".kt": ["//"],
    ".kts": ["//"],
    ".java": ["//"],
    ".js": ["//"],
    ".ts": ["//"],
    ".tsx": ["//"],
    ".jsx": ["//"],
    ".py": ["#"],
    ".sh": ["#"],
    ".yaml": ["#"],
    ".yml": ["#"],
    ".properties": ["#", "!"],
    ".gradle": ["//"],
    ".swift": ["//"],
    ".c": ["//"],
    ".cc": ["//"],
    ".cpp": ["//"],
    ".h": ["//"],
    ".hpp": ["//"],
}

TODO_MARKERS = ("TODO", "FIXME", "HACK", "XXX")


@dataclass
class FileStats:
    path: str
    name: str
    extension: str
    size_bytes: int
    total_lines: int
    non_empty_lines: int
    comment_lines: int
    todo_count: int
    is_text: bool


def is_probably_text_file(path: Path) -> bool:
    if path.suffix.lower() in TEXT_EXTENSIONS:
        return True
    try:
        with path.open("rb") as f:
            chunk = f.read(2048)
        if b"\x00" in chunk:
            return False
        chunk.decode("utf-8")
        return True
    except Exception:
        return False


def count_file_stats(path: Path, root: Path) -> FileStats:
    rel_path = path.relative_to(root).as_posix()
    extension = path.suffix.lower()
    size_bytes = path.stat().st_size

    is_text = is_probably_text_file(path)
    total_lines = 0
    non_empty_lines = 0
    comment_lines = 0
    todo_count = 0

    if is_text:
        comment_prefixes = COMMENT_PREFIXES_BY_EXT.get(extension, [])
        try:
            with path.open("r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    total_lines += 1
                    stripped = line.strip()

                    if stripped:
                        non_empty_lines += 1

                    if any(marker in line for marker in TODO_MARKERS):
                        todo_count += sum(line.count(marker) for marker in TODO_MARKERS)

                    if stripped and any(stripped.startswith(prefix) for prefix in comment_prefixes):
                        comment_lines += 1
        except Exception:
            # Fallback if a text file still fails to read
            is_text = False

    return FileStats(
        path=rel_path,
        name=path.name,
        extension=extension,
        size_bytes=size_bytes,
        total_lines=total_lines,
        non_empty_lines=non_empty_lines,
        comment_lines=comment_lines,
        todo_count=todo_count,
        is_text=is_text,
    )


def should_ignore(path: Path, ignored_dirs: set[str], ignored_files: set[str]) -> bool:
    parts = set(path.parts)
    if path.name in ignored_files:
        return True
    if parts & ignored_dirs:
        return True
    return False


def walk_files(root: Path, ignored_dirs: set[str], ignored_files: set[str]) -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(root):
        current_dir = Path(dirpath)

        dirnames[:] = [
            d for d in dirnames
            if d not in ignored_dirs and not should_ignore(current_dir / d, ignored_dirs, ignored_files)
        ]

        for filename in filenames:
            file_path = current_dir / filename
            if should_ignore(file_path, ignored_dirs, ignored_files):
                continue
            yield file_path


def build_tree(root: Path, max_depth: int, ignored_dirs: set[str], ignored_files: set[str]) -> str:
    lines: list[str] = [f"{root.name}/"]

    def recurse(directory: Path, prefix: str = "", depth: int = 0) -> None:
        if depth >= max_depth:
            return

        children = []
        try:
            for child in sorted(directory.iterdir(), key=lambda p: (p.is_file(), p.name.lower())):
                if should_ignore(child, ignored_dirs, ignored_files):
                    continue
                children.append(child)
        except PermissionError:
            return

        for i, child in enumerate(children):
            is_last = i == len(children) - 1
            connector = "└── " if is_last else "├── "
            lines.append(f"{prefix}{connector}{child.name}")

            if child.is_dir():
                extension = "    " if is_last else "│   "
                recurse(child, prefix + extension, depth + 1)

    recurse(root)
    return "\n".join(lines)


def human_bytes(size: int) -> str:
    units = ["B", "KB", "MB", "GB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.1f} {unit}"
        value /= 1024
    return f"{size} B"


def group_by_directory(file_stats: list[FileStats]) -> dict[str, dict]:
    result: dict[str, dict] = defaultdict(lambda: {
        "file_count": 0,
        "text_file_count": 0,
        "size_bytes": 0,
        "total_lines": 0,
        "non_empty_lines": 0,
        "comment_lines": 0,
        "todo_count": 0,
    })

    for fs in file_stats:
        directory = str(Path(fs.path).parent).replace("\\", "/")
        if directory == ".":
            directory = "/"

        entry = result[directory]
        entry["file_count"] += 1
        entry["size_bytes"] += fs.size_bytes
        entry["todo_count"] += fs.todo_count

        if fs.is_text:
            entry["text_file_count"] += 1
            entry["total_lines"] += fs.total_lines
            entry["non_empty_lines"] += fs.non_empty_lines
            entry["comment_lines"] += fs.comment_lines

    return dict(result)


def find_duplicate_filenames(file_stats: list[FileStats]) -> dict[str, list[str]]:
    grouped: dict[str, list[str]] = defaultdict(list)
    for fs in file_stats:
        grouped[fs.name].append(fs.path)
    return {name: paths for name, paths in grouped.items() if len(paths) > 1}


def top_n(items: list, key, n: int = 20):
    return sorted(items, key=key, reverse=True)[:n]


def write_csv(file_stats: list[FileStats], output_path: Path) -> None:
    with output_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "path",
                "name",
                "extension",
                "size_bytes",
                "total_lines",
                "non_empty_lines",
                "comment_lines",
                "todo_count",
                "is_text",
            ],
        )
        writer.writeheader()
        for row in file_stats:
            writer.writerow(asdict(row))


def build_summary_markdown(
    root: Path,
    file_stats: list[FileStats],
    tree: str,
    per_dir: dict[str, dict],
    duplicates: dict[str, list[str]],
    large_file_line_threshold: int,
) -> str:
    total_files = len(file_stats)
    text_files = sum(1 for f in file_stats if f.is_text)
    total_size = sum(f.size_bytes for f in file_stats)
    total_lines = sum(f.total_lines for f in file_stats if f.is_text)
    total_non_empty = sum(f.non_empty_lines for f in file_stats if f.is_text)
    total_comments = sum(f.comment_lines for f in file_stats if f.is_text)
    total_todos = sum(f.todo_count for f in file_stats)

    by_ext = Counter(f.extension or "<no_ext>" for f in file_stats)
    biggest_files = top_n(file_stats, key=lambda f: f.total_lines if f.is_text else -1, n=25)
    biggest_dirs = top_n(
        [{"path": k, **v} for k, v in per_dir.items()],
        key=lambda d: d["total_lines"],
        n=20,
    )
    suspicious_files = [
        f for f in sorted(file_stats, key=lambda x: x.total_lines, reverse=True)
        if f.is_text and f.total_lines >= large_file_line_threshold
    ][:30]

    md: list[str] = []
    md.append(f"# Project audit: {root.name}")
    md.append("")
    md.append("## Overview")
    md.append("")
    md.append(f"- Total files: **{total_files}**")
    md.append(f"- Text files: **{text_files}**")
    md.append(f"- Total size: **{human_bytes(total_size)}**")
    md.append(f"- Total text lines: **{total_lines}**")
    md.append(f"- Total non-empty text lines: **{total_non_empty}**")
    md.append(f"- Total comment lines: **{total_comments}**")
    md.append(f"- Total TODO/FIXME/HACK markers: **{total_todos}**")
    md.append("")

    md.append("## Project tree")
    md.append("")
    md.append("```text")
    md.append(tree)
    md.append("```")
    md.append("")

    md.append("## File types")
    md.append("")
    for ext, count in by_ext.most_common():
        md.append(f"- `{ext}`: {count}")
    md.append("")

    md.append("## Largest files by line count")
    md.append("")
    md.append("| File | Lines | Non-empty | Comments | TODOs | Size |")
    md.append("|---|---:|---:|---:|---:|---:|")
    for fs in biggest_files:
        if not fs.is_text:
            continue
        md.append(
            f"| `{fs.path}` | {fs.total_lines} | {fs.non_empty_lines} | "
            f"{fs.comment_lines} | {fs.todo_count} | {human_bytes(fs.size_bytes)} |"
        )
    md.append("")

    md.append(f"## Suspiciously large files (>= {large_file_line_threshold} lines)")
    md.append("")
    if suspicious_files:
        for fs in suspicious_files:
            md.append(f"- `{fs.path}` — {fs.total_lines} lines")
    else:
        md.append("- None")
    md.append("")

    md.append("## Largest directories by text line count")
    md.append("")
    md.append("| Directory | Files | Text files | Lines | TODOs | Size |")
    md.append("|---|---:|---:|---:|---:|---:|")
    for d in biggest_dirs:
        md.append(
            f"| `{d['path']}` | {d['file_count']} | {d['text_file_count']} | "
            f"{d['total_lines']} | {d['todo_count']} | {human_bytes(d['size_bytes'])} |"
        )
    md.append("")

    md.append("## Duplicate filenames")
    md.append("")
    if duplicates:
        for name, paths in sorted(duplicates.items()):
            md.append(f"- `{name}`")
            for p in paths:
                md.append(f"  - `{p}`")
    else:
        md.append("- None")
    md.append("")

    md.append("## Recommended cleanup targets")
    md.append("")
    md.append("Prioritize these first:")
    md.append("")
    md.append("1. Files over ~300–500 lines, especially UI/state files.")
    md.append("2. Directories with high line count and many TODOs.")
    md.append("3. Duplicate filename patterns that make navigation confusing.")
    md.append("4. Files with low comments but very high non-empty line counts.")
    md.append("5. Any screen/provider/service doing too many things at once.")
    md.append("")

    return "\n".join(md)


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit project structure and file metrics.")
    parser.add_argument(
        "root",
        nargs="?",
        default=".",
        help="Project root directory (default: current directory)",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        default=4,
        help="Max depth for directory tree output (default: 4)",
    )
    parser.add_argument(
        "--large-file-threshold",
        type=int,
        default=400,
        help="Threshold for suspiciously large files by line count (default: 400)",
    )
    parser.add_argument(
        "--out-dir",
        default=".",
        help="Directory for generated reports (default: current directory)",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    file_stats: list[FileStats] = []
    for file_path in walk_files(root, DEFAULT_IGNORED_DIRS, DEFAULT_IGNORED_FILES):
        if file_path.is_file():
            file_stats.append(count_file_stats(file_path, root))

    file_stats.sort(key=lambda f: f.path.lower())

    tree = build_tree(root, args.max_depth, DEFAULT_IGNORED_DIRS, DEFAULT_IGNORED_FILES)
    per_dir = group_by_directory(file_stats)
    duplicates = find_duplicate_filenames(file_stats)

    summary_md = build_summary_markdown(
        root=root,
        file_stats=file_stats,
        tree=tree,
        per_dir=per_dir,
        duplicates=duplicates,
        large_file_line_threshold=args.large_file_threshold,
    )

    summary_path = out_dir / "project_audit_summary.md"
    csv_path = out_dir / "project_audit_files.csv"
    json_path = out_dir / "project_audit.json"

    summary_path.write_text(summary_md, encoding="utf-8")
    write_csv(file_stats, csv_path)

    payload = {
        "project_root": str(root),
        "files": [asdict(fs) for fs in file_stats],
        "directories": per_dir,
        "duplicate_filenames": duplicates,
        "settings": {
            "max_depth": args.max_depth,
            "large_file_threshold": args.large_file_threshold,
            "ignored_dirs": sorted(DEFAULT_IGNORED_DIRS),
            "ignored_files": sorted(DEFAULT_IGNORED_FILES),
        },
    }
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"Done.")
    print(f"Summary: {summary_path}")
    print(f"CSV:     {csv_path}")
    print(f"JSON:    {json_path}")


if __name__ == "__main__":
    main()