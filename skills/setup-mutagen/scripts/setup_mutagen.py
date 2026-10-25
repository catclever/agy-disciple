#!/usr/bin/env python3
"""
setup_mutagen.py
Automated project inspector and Mutagen configuration / session generator.
Detects project types (including monorepos, Wails desktop apps, Go, Node, Python, Rust, etc.),
constructs optimal ignore rules (handling nested frontend build outputs and binary packaging outputs),
and configures sync sessions to the remote server.
Supports both declarative configuration (mutagen.yml + mutagen project start) and ad-hoc sessions.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

COMMON_IGNORES: List[str] = [
    ".DS_Store",
    ".AppleDouble",
    ".LSOverride",
    "Thumbs.db",
    ".idea/",
    ".vscode/",
    "*.swp",
    "*.swo",
    "*~",
    ".agent/",
    ".gemini/",
    ".codex/",
    "*.log",
    "tmp/",
    "temp/",
]

LANGUAGE_RULES: Dict[str, Dict[str, any]] = {
    "Go": {
        "indicators": ["go.mod", "go.sum", "go.work"],
        "extensions": [".go"],
        "ignores": [
            "bin/",
            "vendor/",
            "*.test",
            "*.out",
            "*.exe",
            "*.dll",
            "*.so",
            "*.dylib",
        ],
    },
    "Node / Frontend": {
        "indicators": [
            "package.json",
            "pnpm-lock.yaml",
            "yarn.lock",
            "bun.lockb",
            "next.config.js",
            "next.config.mjs",
            "next.config.ts",
            "vite.config.js",
            "vite.config.ts",
            "astro.config.mjs",
        ],
        "extensions": [".js", ".jsx", ".ts", ".tsx", ".vue", ".svelte"],
        "ignores": [
            "node_modules/",
            "dist/",
            "build/",
            ".next/",
            ".nuxt/",
            ".output/",
            ".svelte-kit/",
            ".astro/",
            ".cache/",
            ".parcel-cache/",
            ".turbo/",
            "coverage/",
        ],
    },
    "Python": {
        "indicators": [
            "pyproject.toml",
            "requirements.txt",
            "setup.py",
            "setup.cfg",
            "Pipfile",
            "uv.lock",
            "poetry.lock",
            "environment.yml",
        ],
        "extensions": [".py"],
        "ignores": [
            ".venv/",
            "venv/",
            "env/",
            "ENV/",
            "__pycache__/",
            "*.py[cod]",
            "*$py.class",
            ".pytest_cache/",
            ".mypy_cache/",
            ".ruff_cache/",
            ".coverage",
            "htmlcov/",
            "dist/",
            "build/",
            "*.egg-info/",
            ".tox/",
        ],
    },
    "Rust": {
        "indicators": ["Cargo.toml", "Cargo.lock"],
        "extensions": [".rs"],
        "ignores": [
            "target/",
        ],
    },
    "Ruby": {
        "indicators": ["Gemfile", "Gemfile.lock"],
        "extensions": [".rb"],
        "ignores": [
            ".bundle/",
            "vendor/bundle/",
        ],
    },
    "Java / JVM": {
        "indicators": ["pom.xml", "build.gradle", "build.gradle.kts", "gradlew"],
        "extensions": [".java", ".kt", ".scala"],
        "ignores": [
            "target/",
            "build/",
            ".gradle/",
            "*.class",
        ],
    },
    "C / C++": {
        "indicators": ["CMakeLists.txt", "Makefile", "meson.build", "configure.ac"],
        "extensions": [".c", ".cpp", ".cc", ".cxx", ".h", ".hpp"],
        "ignores": [
            "build/",
            "cmake-build-*/",
            "*.o",
            "*.obj",
            "*.a",
            "*.lib",
            "*.so",
            "*.dylib",
        ],
    },
    "Swift": {
        "indicators": ["Package.swift"],
        "extensions": [".swift"],
        "ignores": [
            ".build/",
            ".swiftpm/",
            "DerivedData/",
        ],
    },
}

SUB_FRONTEND_DIRS = ["frontend", "client", "web", "ui", "app", "dashboard"]


def detect_wails_project(root_dir: Path) -> Tuple[bool, List[str]]:
    """Detects Wails desktop project and returns tailored packaging & build output ignores."""
    wails_config = root_dir / "wails.json"
    if not wails_config.exists():
        return False, []

    frontend_dir = "frontend"
    try:
        data = json.loads(wails_config.read_text(encoding="utf-8"))
        frontend_dir = data.get("frontend:dir", "frontend").strip()
    except Exception:
        pass

    ignores = [
        "build/bin/",                 # Wails compiled native binaries (.app, ELF binaries)
        "build/windows/*.syso",       # Windows resource binaries
        f"{frontend_dir}/dist/",      # Frontend build artifacts embedded by //go:embed
        f"{frontend_dir}/node_modules/",
        f"{frontend_dir}/.turbo/",
        f"{frontend_dir}/dist-ssr/",
        "wails-*.log",
    ]
    return True, ignores


def detect_nested_frontends(root_dir: Path) -> List[Tuple[str, List[str]]]:
    """Inspects subdirectories (frontend/, web/, client/) for nested frontend projects."""
    detected = []
    frontend_indicators = [
        "package.json", "pnpm-lock.yaml", "yarn.lock", "bun.lockb",
        "vite.config.js", "vite.config.ts", "next.config.js"
    ]

    for sub in SUB_FRONTEND_DIRS:
        sub_path = root_dir / sub
        if not sub_path.is_dir():
            continue

        entries = set(os.listdir(sub_path))
        if any(ind in entries for ind in frontend_indicators):
            detected.append((
                f"Nested Frontend ({sub}/)",
                [
                    f"{sub}/node_modules/",
                    f"{sub}/dist/",
                    f"{sub}/build/",
                    f"{sub}/.next/",
                    f"{sub}/.nuxt/",
                    f"{sub}/.turbo/",
                    f"{sub}/coverage/",
                ]
            ))
    return detected


def detect_project_types(root_dir: Path) -> List[Tuple[str, List[str]]]:
    """Detects languages/ecosystems present in the directory, including Wails and nested setups."""
    detected = []
    
    root_entries = set()
    try:
        for entry in root_dir.iterdir():
            root_entries.add(entry.name)
    except Exception as e:
        print(f"Warning: could not read directory {root_dir}: {e}", file=sys.stderr)
        return []

    # 1. Check for Wails Desktop Project
    is_wails, wails_ignores = detect_wails_project(root_dir)
    if is_wails:
        detected.append(("Wails Desktop (Go + Embedded Frontend)", wails_ignores))

    # 2. Check for Root Level Manifest Indicators
    for lang, rule in LANGUAGE_RULES.items():
        matched_indicators = [ind for ind in rule["indicators"] if ind in root_entries]
        if matched_indicators:
            ignores = list(rule["ignores"])
            if is_wails and "build/" in ignores:
                ignores.remove("build/")
            detected.append((lang, ignores))
            continue

        # Fallback to extensions check in root
        has_ext = any(
            any(f.endswith(ext) for ext in rule["extensions"])
            for f in root_entries
        )
        if has_ext:
            ignores = list(rule["ignores"])
            if is_wails and "build/" in ignores:
                ignores.remove("build/")
            detected.append((lang, ignores))

    # 3. Check for Nested Subdirectory Frontends
    if not is_wails:
        nested_frontends = detect_nested_frontends(root_dir)
        detected.extend(nested_frontends)

    return detected


def assemble_ignores(detected: List[Tuple[str, List[str]]], custom_ignores: List[str] = None) -> List[str]:
    """Combines common, language-specific, and custom ignores into an ordered deduplicated list."""
    seen = set()
    result = []

    def add_ignore(pattern: str):
        cleaned = pattern.strip()
        if cleaned and cleaned not in seen:
            seen.add(cleaned)
            result.append(cleaned)

    for item in COMMON_IGNORES:
        add_ignore(item)

    for _, lang_ignores in detected:
        for item in lang_ignores:
            add_ignore(item)

    if custom_ignores:
        for item in custom_ignores:
            add_ignore(item)

    return result


def generate_mutagen_yaml(project_name: str, remote_host: str, remote_dir: str, ignores: List[str]) -> str:
    """Generates the content for a declarative mutagen.yml configuration."""
    yaml_lines = [
        "# Generated automatically by setup-mutagen skill",
        "sync:",
        "  defaults:",
        '    mode: "two-way-resolved"',
        "    ignore:",
        "      vcs: true",
        "      paths:",
    ]
    for pattern in ignores:
        yaml_lines.append(f'        - "{pattern}"')
    
    yaml_lines.extend([
        "    symlink:",
        '      mode: "posix-raw"',
        "",
        f"  {project_name}:",
        '    alpha: "."',
        f'    beta: "{remote_host}:{remote_dir}"',
    ])
    return "\n".join(yaml_lines) + "\n"


def build_mutagen_command(
    project_name: str,
    local_dir: str,
    remote_host: str,
    remote_dir: str,
    ignores: List[str]
) -> List[str]:
    """Builds the ad-hoc mutagen sync create command."""
    cmd = [
        "mutagen", "sync", "create",
        f"--name={project_name}",
        "--mode=two-way-resolved",
        "--ignore-vcs",
    ]
    for pattern in ignores:
        cmd.extend(["-i", pattern])
    cmd.append(local_dir)
    cmd.append(f"{remote_host}:{remote_dir}")
    return cmd


def ensure_remote_dir(remote_host: str, remote_dir: str):
    """Ensures the remote directory exists via SSH."""
    print(f"Ensuring remote directory exists ({remote_host}:{remote_dir})...")
    mkdir_cmd = ["ssh", remote_host, f"mkdir -p {remote_dir}"]
    try:
        res = subprocess.run(mkdir_cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"Warning: SSH mkdir exited with code {res.returncode}: {res.stderr}", file=sys.stderr)
    except Exception as e:
        print(f"Warning: Failed to create remote directory via SSH: {e}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Setup Mutagen Sync with Smart Language Detection")
    parser.add_argument("--dir", default=".", help="Local project directory (default: current directory)")
    parser.add_argument("--name", help="Session / Project name (default: basename of target directory)")
    parser.add_argument("--remote-host", default=os.getenv("AGY_REMOTE_HOST", "remote-server"), help="Remote SSH alias (default: $AGY_REMOTE_HOST or remote-server)")
    parser.add_argument("--remote-base", default=os.getenv("AGY_REMOTE_BASE", "~/Projects"), help="Remote base directory (default: $AGY_REMOTE_BASE or ~/Projects)")
    parser.add_argument("--remote-dir", help="Explicit remote path. Defaults to <remote-base>/<project_name>")
    parser.add_argument("--ignore", action="append", default=[], help="Additional ignore pattern (repeatable)")
    parser.add_argument("--write-config", action="store_true", help="Write mutagen.yml to project directory")
    parser.add_argument("--start", action="store_true", help="Write mutagen.yml and run `mutagen project start` (Standard Workflow)")
    parser.add_argument("--create", action="store_true", help="Directly execute `mutagen sync create` (Ad-hoc session)")
    parser.add_argument("--dry-run", action="store_true", help="Print plans and commands without making changes")

    args = parser.parse_args()

    project_path = Path(args.dir).resolve()
    if not project_path.is_dir():
        print(f"Error: {project_path} is not a valid directory.", file=sys.stderr)
        sys.exit(1)

    folder_name = project_path.name
    project_name = args.name or folder_name.replace("_", "-")
    remote_dir = args.remote_dir or f"{args.remote_base.rstrip('/')}/{folder_name}"

    detected = detect_project_types(project_path)
    detected_names = [name for name, _ in detected] or ["Generic / Unknown"]
    ignores = assemble_ignores(detected, args.ignore)

    print(f"==================================================")
    print(f" Mutagen Sync Setup Inspector")
    print(f"==================================================")
    print(f" Project Directory : {project_path}")
    print(f" Project Name      : {project_name}")
    print(f" Detected Types    : {', '.join(detected_names)}")
    print(f" Remote Target     : {args.remote_host}:{remote_dir}")
    print(f" Ignore Rules      : {len(ignores)} patterns (plus VCS/git rules)")
    print(f"==================================================")

    yaml_content = generate_mutagen_yaml(project_name, args.remote_host, remote_dir, ignores)
    cli_cmd = build_mutagen_command(project_name, str(project_path), args.remote_host, remote_dir, ignores)

    # 1. Dry Run / Inspection Only
    if args.dry_run or (not args.write_config and not args.create and not args.start):
        print("\n--- Proposed Declarative Config (mutagen.yml) ---")
        print(yaml_content)
        print("--- Standard Start Command ---")
        print(f"cd {project_path} && mutagen project start")
        print("\n--- Ad-hoc CLI Alternative ---")
        print(" \\\n  ".join([
            cli_cmd[0] + " " + cli_cmd[1] + " " + cli_cmd[2],
            cli_cmd[3],
            cli_cmd[4],
            cli_cmd[5],
            *[f'{cli_cmd[i]} "{cli_cmd[i+1]}"' for i in range(6, len(cli_cmd) - 2, 2)],
            f'"{cli_cmd[-2]}"',
            f'"{cli_cmd[-1]}"',
        ]))
        print("\nQuick Actions:")
        print("  • Standard: --start        (Write mutagen.yml + run `mutagen project start`)")
        print("  • Config only: --write-config (Write mutagen.yml without starting)")
        print("  • Ad-hoc:    --create       (Run `mutagen sync create` directly)")
        return

    # 2. Standard Workflow: Write mutagen.yml and run mutagen project start
    if args.start:
        ensure_remote_dir(args.remote_host, remote_dir)
        config_path = project_path / "mutagen.yml"
        print(f"Writing configuration to {config_path}...")
        config_path.write_text(yaml_content, encoding="utf-8")
        print("Executing `mutagen project start`...")
        try:
            res = subprocess.run(["mutagen", "project", "start"], cwd=project_path, capture_output=True, text=True)
            if res.returncode == 0:
                print(f"Successfully started Mutagen project for: {project_name}")
                if res.stdout.strip():
                    print(res.stdout)
                print(f"Check status anytime with: mutagen project list (or mutagen sync list)")
            else:
                print(f"Error starting Mutagen project:\n{res.stderr}", file=sys.stderr)
                sys.exit(res.returncode)
        except Exception as e:
            print(f"Execution failed: {e}", file=sys.stderr)
            sys.exit(1)
        return

    # 3. Write Config Only
    if args.write_config:
        config_path = project_path / "mutagen.yml"
        print(f"Writing configuration to {config_path}...")
        config_path.write_text(yaml_content, encoding="utf-8")
        print(f"Done. To start the sync, run: cd {project_path} && mutagen project start")

    # 4. Ad-hoc Direct Session Creation
    if args.create:
        ensure_remote_dir(args.remote_host, remote_dir)
        print(f"Running mutagen sync create...")
        try:
            res = subprocess.run(cli_cmd, capture_output=True, text=True)
            if res.returncode == 0:
                print(f"Successfully created Mutagen sync session: {project_name}")
                print(res.stdout)
            else:
                print(f"Error creating Mutagen session:\n{res.stderr}", file=sys.stderr)
                sys.exit(res.returncode)
        except Exception as e:
            print(f"Execution failed: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
