#!/usr/bin/env python3
"""
configure.py
Preset, Mode Switcher & Environment Doctor for agy-disciple Antigravity Plugin.
Allows one-command switching between Local-First / Server topologies and In-Repo / Centralized metadata modes.
"""

import os
import sys
import shutil
from pathlib import Path

ROOT = Path(__file__).parent.resolve()
SKILLS_DIR = ROOT / "skills"

VARIANTS = {
    # skill_name: (in_repo/centralized key, local/server key)
    "project-manager": {
        "in-repo": "SKILL.in-repo.md",
        "centralized": "SKILL.centralized.md"
    },
    "extract-knowledge": {
        "in-repo": "SKILL.in-repo.md",
        "centralized": "SKILL.centralized.md"
    },
    "dev-manager": {
        "local": "SKILL.local.md",
        "server": "SKILL.server.md"
    },
    "test-environment": {
        "local": "SKILL.local.md",
        "server": "SKILL.server.md"
    },
    "night-shift": {
        "local": "SKILL.local.md",
        "server": "SKILL.server.md"
    }
}


def apply_variant(skill_name: str, variant_file: str):
    skill_path = SKILLS_DIR / skill_name
    src = skill_path / variant_file
    dest = skill_path / "SKILL.md"
    if src.exists():
        shutil.copyfile(src, dest)
        print(f"  [✓] {skill_name}: Applied {variant_file} -> SKILL.md")
    else:
        print(f"  [!] {skill_name}: Source {variant_file} not found.")


def show_status():
    print("==================================================")
    print(" agy-disciple Configuration Status")
    print("==================================================")
    for skill_name, mapping in VARIANTS.items():
        dest = SKILLS_DIR / skill_name / "SKILL.md"
        if not dest.exists():
            print(f"  • {skill_name:20}: [Missing SKILL.md]")
            continue
        
        current_content = dest.read_text(encoding="utf-8")
        matched = "Custom / Unknown"
        for label, filename in mapping.items():
            src = SKILLS_DIR / skill_name / filename
            if src.exists() and src.read_text(encoding="utf-8") == current_content:
                matched = f"{label} ({filename})"
                break
        print(f"  • {skill_name:20}: {matched}")
    print("==================================================")


def run_doctor():
    print("==================================================")
    print(" agy-disciple Environment Doctor")
    print("==================================================")
    
    # 1. Core Local
    print("[1] Core Local Prerequisites (Local-First Mode)")
    git_path = shutil.which("git")
    if git_path:
        print(f"  [✓] Git                    : Found ({git_path})")
    else:
        print("  [✗] Git                    : Missing! Please install Git.")
        
    py_ver = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    if sys.version_info >= (3, 8):
        print(f"  [✓] Python                 : Python {py_ver}")
    else:
        print(f"  [✗] Python                 : Python {py_ver} (Recommend >= 3.8)")
    print("  -> Status: Local development inside Antigravity IDE is 100% READY!\n")
    
    # 2. Server & Headless
    print("[2] Server & Headless Prerequisites (Remote Server / PVE)")
    agy_path = shutil.which("agy")
    if agy_path:
        print(f"  [✓] Antigravity CLI (agy)  : Found ({agy_path})")
    else:
        print("  [i] Antigravity CLI (agy)  : Not found in local PATH.")
        print("                              Note: Only required on target server (or terminal) for headless/remote runs.")
        print("                              See: https://antigravity.google/docs/cli")
        
    ssh_path = shutil.which("ssh")
    if ssh_path:
        print(f"  [✓] SSH Client             : Found ({ssh_path})")
    else:
        print("  [!] SSH Client             : Missing! (Required for remote server dispatch)")

    zellij_path = shutil.which("zellij")
    if zellij_path:
        print(f"  [✓] Zellij Multiplexer     : Found ({zellij_path})")
    else:
        print("  [i] Zellij Multiplexer     : Not found locally. (Required on remote server for persistent sessions)")

    mutagen_path = shutil.which("mutagen")
    if mutagen_path:
        print(f"  [✓] Mutagen Sync           : Found ({mutagen_path})")
    else:
        print("  [i] Mutagen Sync           : Not found. (Optional: install via `brew install mutagen` for two-way sync)")
    print("")

    # 3. Google Jules
    print("[3] Google Jules Autonomous Cloud Pipeline")
    jules_api_key = os.getenv("JULES_API_KEY")
    jules_cli = shutil.which("jules")
    if jules_api_key:
        print(f"  [✓] Jules API Key          : Configured ($JULES_API_KEY detected)")
    elif jules_cli:
        print(f"  [✓] Jules CLI              : Found ({jules_cli})")
    else:
        print("  [i] Jules Auth             : Neither $JULES_API_KEY nor `jules` CLI detected.")
        print("                              (Required if using Jules autonomous dispatch in night-shift / pve-dispatch)")

    gh_path = shutil.which("gh")
    if gh_path:
        print(f"  [✓] GitHub CLI (gh)        : Found ({gh_path})")
    else:
        print("  [i] GitHub CLI (gh)        : Not found. (Optional: needed for Jules PR auto-merge)")

    uv_path = shutil.which("uv")
    if uv_path:
        print(f"  [✓] uv (FastMCP Runner)    : Found ({uv_path})")
    else:
        print("  [i] uv                     : Not found. (Optional: needed for running bundled FastMCP kanban server)")

    print("==================================================")


def set_preset(preset_name: str):
    print(f"\nApplying preset: [{preset_name}]...")
    if preset_name in ["standalone", "local", "default"]:
        apply_variant("project-manager", VARIANTS["project-manager"]["in-repo"])
        apply_variant("extract-knowledge", VARIANTS["extract-knowledge"]["in-repo"])
        apply_variant("dev-manager", VARIANTS["dev-manager"]["local"])
        apply_variant("test-environment", VARIANTS["test-environment"]["local"])
        apply_variant("night-shift", VARIANTS["night-shift"]["local"])
        print("\nSuccessfully switched to: [Standalone / Local-First / In-Repo] mode.")

    elif preset_name in ["server-centralized", "pve", "power-user"]:
        apply_variant("project-manager", VARIANTS["project-manager"]["centralized"])
        apply_variant("extract-knowledge", VARIANTS["extract-knowledge"]["centralized"])
        apply_variant("dev-manager", VARIANTS["dev-manager"]["server"])
        apply_variant("test-environment", VARIANTS["test-environment"]["server"])
        apply_variant("night-shift", VARIANTS["night-shift"]["server"])
        print("\nSuccessfully switched to: [Server-Centralized / Remote Server] mode.")
    else:
        print(f"Unknown preset: '{preset_name}'. Supported presets: 'standalone', 'server-centralized'")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Configure agy-disciple skill presets and diagnose environment")
    parser.add_argument("--status", action="store_true", help="Show current active skill modes")
    parser.add_argument("--doctor", action="store_true", help="Diagnose environment prerequisites for all modes")
    parser.add_argument("--preset", choices=["standalone", "local", "server-centralized", "pve"],
                        help="Quick apply a predefined configuration preset")
    parser.add_argument("--meta", choices=["in-repo", "centralized"], help="Set metadata storage mode")
    parser.add_argument("--topology", choices=["local", "server"], help="Set execution topology")

    args = parser.parse_args()

    if args.doctor:
        run_doctor()
        return

    if args.status or (not args.preset and not args.meta and not args.topology):
        show_status()
        print("\nUsage Examples:")
        print("  python configure.py --doctor                     # Diagnose CLI tools and prerequisites")
        print("  python configure.py --preset=standalone          # Local standalone + In-Repo (Default)")
        print("  python configure.py --preset=server-centralized   # Remote server + Centralized metadata")
        print("  python configure.py --meta=centralized           # Only change metadata mode")
        print("  python configure.py --topology=server            # Only change server mode")
        return

    if args.preset:
        set_preset(args.preset)

    if args.meta:
        apply_variant("project-manager", VARIANTS["project-manager"][args.meta])
        apply_variant("extract-knowledge", VARIANTS["extract-knowledge"][args.meta])

    if args.topology:
        apply_variant("dev-manager", VARIANTS["dev-manager"][args.topology])
        apply_variant("test-environment", VARIANTS["test-environment"][args.topology])
        apply_variant("night-shift", VARIANTS["night-shift"][args.topology])


if __name__ == "__main__":
    main()
