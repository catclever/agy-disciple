#!/usr/bin/env python3
"""
meta_resolver.py
Resolves project metadata paths for Antigravity workspaces.
Supports both In-Repository mode (<workspace>/) and Centralized mode (~/.gemini/Projects/<name>/).
Incorporates multi-root discovery, case-insensitive matching, GitHub slug resolution,
and Cloud Remote sandbox (/workspace/<project>) / remote server fallbacks.
"""

import os
import sys
import json
from pathlib import Path
from glob import glob
from urllib.parse import unquote


def _resolve_gemini_roots() -> tuple[Path, Path]:
    """
    Resolves (gemini_projects_root, projects_dir) across Mac, Remote Server Linux,
    and Google Cloud Remote Agent sandboxes (/workspace/gemini-hub/Projects).
    """
    candidates = [
        os.environ.get("PROJECTS_ROOT"),
        "/workspace/gemini-hub/Projects",
        os.path.expanduser("~/.gemini/Projects"),
    ]

    gemini_projects_root = None
    for cand in candidates:
        if cand:
            try:
                p = Path(os.path.expanduser(cand))
                if p.is_dir():
                    gemini_projects_root = p.resolve()
                    break
            except Exception:
                pass

    if not gemini_projects_root:
        gemini_projects_root = Path(os.path.expanduser("~/.gemini/Projects"))

    hub_root = gemini_projects_root.parent
    candidate_projects_cfg = hub_root / "config" / "projects"
    try:
        if candidate_projects_cfg.is_dir():
            projects_dir = candidate_projects_cfg
        else:
            projects_dir = Path(os.path.expanduser("~/.gemini/config/projects"))
    except Exception:
        projects_dir = Path(os.path.expanduser("~/.gemini/config/projects"))

    return gemini_projects_root, projects_dir


def list_valid_projects() -> list[str]:
    gemini_projects_root, projects_dir = _resolve_gemini_roots()
    valid = set()
    try:
        if projects_dir.exists():
            for json_file in projects_dir.glob("*.json"):
                try:
                    data = json.loads(json_file.read_text(encoding="utf-8"))
                    name = data.get("name")
                    if name and name != "Outside of Project":
                        valid.add(Path(name.rstrip("/")).name)
                except Exception:
                    pass
    except Exception:
        pass

    try:
        if gemini_projects_root.exists():
            for item in gemini_projects_root.iterdir():
                if item.is_dir() and not item.name.startswith((".", "_")):
                    valid.add(item.name)
    except Exception:
        pass
    return sorted(list(valid))


def find_repo_root(start_path: Path) -> Path:
    """Walk up from start_path to find .git directory or project root."""
    try:
        curr = start_path.resolve()
        while curr != curr.parent:
            if (curr / ".git").exists():
                return curr
            curr = curr.parent
        return start_path.resolve()
    except Exception:
        return start_path


def get_in_repo_meta_dir(query_path: str = None) -> str:
    """Resolves metadata directory within the project's repository."""
    start = Path(query_path).resolve() if query_path else Path.cwd()
    root = find_repo_root(start)
    return str(root)


def get_centralized_meta_dir(query: str = None) -> str:
    """
    Resolves centralized metadata directory in ~/.gemini/Projects/<project_name>.
    Supports:
    1. Project ID
    2. Case-insensitive project name
    3. GitHub owner/repo slug
    4. Path matching (Mac, remote server /root/Projects, Cloud /workspace)
    5. ID auto-healing
    """
    gemini_projects_root, projects_dir = _resolve_gemini_roots()

    name_mappings: dict[str, tuple[str, str]] = {}
    path_mappings: dict[str, tuple[str, str]] = {}
    id_mappings: dict[str, tuple[str, str]] = {}

    try:
        if projects_dir.exists():
            for json_file in projects_dir.glob("*.json"):
                try:
                    data = json.loads(json_file.read_text(encoding="utf-8"))
                    pid = data.get("id")
                    raw_name = data.get("name", "")
                    if not raw_name or not pid:
                        continue
                    safe_name = Path(raw_name.rstrip("/")).name
                    name_mappings[safe_name.lower()] = (pid, safe_name)
                    id_mappings[pid] = (pid, safe_name)

                    resources = data.get("projectResources", {}).get("resources", [])
                    for res in resources:
                        uri = res.get("gitFolder", {}).get("folderUri", "") or res.get("folderUri", "")
                        if uri.startswith("file://"):
                            path = unquote(uri[7:])
                            path_mappings[str(Path(path).resolve())] = (pid, safe_name)
                except Exception:
                    continue
    except Exception:
        pass

    try:
        if gemini_projects_root.exists():
            for item in gemini_projects_root.iterdir():
                if item.is_dir() and not item.name.startswith((".", "_")):
                    if item.name.lower() not in name_mappings:
                        pid = None
                        id_file = item / ".project_id"
                        if id_file.exists():
                            try:
                                pid = id_file.read_text(encoding="utf-8").strip()
                            except Exception:
                                pass
                        name_mappings[item.name.lower()] = (pid or item.name, item.name)
    except Exception:
        pass

    q = os.path.expandvars(str(query or os.getcwd()).strip())
    target_pid = None
    target_name = None

    # 1. Match by project ID
    if q in id_mappings:
        target_pid, target_name = id_mappings[q]
    # 2. Match by exact or case-insensitive project name
    elif q.lower() in name_mappings:
        target_pid, target_name = name_mappings[q.lower()]
    # 3. Match by GitHub owner/repo slug (e.g. "my-org/my-project")
    elif (
        "/" in q
        and not q.startswith(("/", "~", "./", "../"))
        and len(q.strip("/").split("/")) == 2
    ):
        repo_slug = q.strip("/").split("/")[-1].lower()
        if repo_slug.endswith(".git"):
            repo_slug = repo_slug[:-4]
        if repo_slug in name_mappings:
            target_pid, target_name = name_mappings[repo_slug]
    # 4. Match by directory path
    elif q.startswith(("/", "~", "./", "../")) or os.path.isabs(q) or os.path.exists(q):
        try:
            curr = Path(os.path.expanduser(q)).resolve()
            while curr != curr.parent:
                if str(curr) in path_mappings:
                    target_pid, target_name = path_mappings[str(curr)]
                    break
                curr = curr.parent
        except Exception:
            pass

        # Cloud sandbox (/workspace/<project>) or remote server (/root/Projects/<project>) fallback
        if not target_name:
            try:
                norm_str = str(Path(os.path.expanduser(q)).resolve())
                for prefix in ("/workspace/", "/root/Projects/", f"{os.getenv('AGY_REMOTE_BASE', '/root/Projects')}/"):
                    if norm_str.startswith(prefix):
                        rel = norm_str[len(prefix):].strip("/")
                        if rel:
                            first_seg = rel.split("/")[0].lower()
                            if first_seg in name_mappings:
                                target_pid, target_name = name_mappings[first_seg]
                                break
            except Exception:
                pass

    if not target_name:
        # Fallback to directory name or raw query
        try:
            target_name = Path(q).resolve().name if os.path.exists(q) or q.startswith(("/", "~", "./")) else q
        except Exception:
            target_name = q

    target_dir = gemini_projects_root / target_name
    try:
        gemini_projects_root.mkdir(parents=True, exist_ok=True)
    except Exception:
        pass

    # Auto-healing: Look for an existing folder with the same project ID
    if target_pid:
        try:
            if gemini_projects_root.exists():
                for folder in gemini_projects_root.iterdir():
                    if not folder.is_dir():
                        continue
                    id_file = folder / ".project_id"
                    if id_file.exists():
                        try:
                            saved_id = id_file.read_text(encoding="utf-8").strip()
                            if saved_id == target_pid and folder.name != target_name:
                                if not target_dir.exists():
                                    folder.rename(target_dir)
                                break
                        except Exception:
                            pass
        except Exception:
            pass

    try:
        target_dir.mkdir(parents=True, exist_ok=True)
    except Exception:
        pass

    if target_pid:
        try:
            id_file = target_dir / ".project_id"
            if not id_file.exists():
                id_file.write_text(target_pid, encoding="utf-8")
        except Exception:
            pass

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
