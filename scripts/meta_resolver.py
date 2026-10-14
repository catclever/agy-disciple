#!/usr/bin/env python3
"""
meta_resolver.py
Resolves project metadata paths for Antigravity workspaces.
Supports both In-Repository mode (<workspace>/) and Centralized mode (~/.gemini/Projects/<name>/).
"""

import os
import sys
import json
from pathlib import Path
from glob import glob
from urllib.parse import unquote


def find_repo_root(start_path: Path) -> Path:
    """Walk up from start_path to find .git directory or project root."""
    curr = start_path.resolve()
    while curr != curr.parent:
        if (curr / ".git").exists():
            return curr
        curr = curr.parent
    return start_path.resolve()


def get_in_repo_meta_dir(query_path: str = None) -> str:
    """Resolves metadata directory within the project's repository."""
    start = Path(query_path).resolve() if query_path else Path.cwd()
    root = find_repo_root(start)
    return str(root)


def get_centralized_meta_dir(query: str = None) -> str:
    """Resolves centralized metadata directory in ~/.gemini/Projects/<project_name>."""
    gemini_projects_root = Path(os.path.expanduser("~/.gemini/Projects"))
    projects_dir = Path(os.path.expanduser("~/.gemini/config/projects"))
    
    target_name = None
    q = (query or os.getcwd()).strip()

    # Search Antigravity project registry if present
    if projects_dir.exists():
        for json_file in projects_dir.glob("*.json"):
            try:
                data = json.loads(json_file.read_text(encoding="utf-8"))
                raw_name = data.get("name", "")
                if raw_name:
                    safe_name = Path(raw_name.rstrip("/")).name
                    resources = data.get("projectResources", {}).get("resources", [])
                    for res in resources:
                        uri = res.get("gitFolder", {}).get("folderUri", "") or res.get("folderUri", "")
                        if uri.startswith("file://"):
                            folder_path = unquote(uri[7:])
                            if Path(q).resolve() == Path(folder_path).resolve():
                                target_name = safe_name
                                break
            except Exception:
                continue

    if not target_name:
        # Fallback to directory name
        target_name = Path(q).resolve().name

    target_dir = gemini_projects_root / target_name
    target_dir.mkdir(parents=True, exist_ok=True)
    return str(target_dir)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Antigravity Project Metadata Path Resolver")
    parser.add_argument("query", nargs="?", default=".", help="Project path or name")
    parser.add_argument("--mode", choices=["in-repo", "centralized"], default="in-repo",
                        help="Metadata storage mode (default: in-repo)")
    args = parser.parse_args()

    if args.mode == "in-repo":
        print(get_in_repo_meta_dir(args.query))
    else:
        print(get_centralized_meta_dir(args.query))


if __name__ == "__main__":
    main()
