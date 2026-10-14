#!/usr/bin/env python3
"""
configure.py
Preset & Mode Switcher for agy-disciple Antigravity Plugin.
Allows one-command switching between Local-First / Server topologies and In-Repo / Centralized metadata modes.
"""

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


def set_preset(preset_name: str):
    print(f"\nApplying preset: [{preset_name}]...")
    if preset_name in ["standalone", "local", "default"]:
        # In-Repo + Local
        apply_variant("project-manager", VARIANTS["project-manager"]["in-repo"])
        apply_variant("extract-knowledge", VARIANTS["extract-knowledge"]["in-repo"])
        apply_variant("dev-manager", VARIANTS["dev-manager"]["local"])
        apply_variant("test-environment", VARIANTS["test-environment"]["local"])
        apply_variant("night-shift", VARIANTS["night-shift"]["local"])
        print("\nSuccessfully switched to: [Standalone / Local-First / In-Repo] mode.")

    elif preset_name in ["server-centralized", "pve", "power-user"]:
        # Centralized + Server
        apply_variant("project-manager", VARIANTS["project-manager"]["centralized"])
        apply_variant("extract-knowledge", VARIANTS["extract-knowledge"]["centralized"])
        apply_variant("dev-manager", VARIANTS["dev-manager"]["server"])
        apply_variant("test-environment", VARIANTS["test-environment"]["server"])
        apply_variant("night-shift", VARIANTS["night-shift"]["server"])
        print("\nSuccessfully switched to: [Server-Centralized / PVE] mode.")
    else:
        print(f"Unknown preset: '{preset_name}'. Supported presets: 'standalone', 'server-centralized'")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Configure agy-disciple skill presets")
    parser.add_argument("--status", action="store_true", help="Show current active skill modes")
    parser.add_argument("--preset", choices=["standalone", "local", "server-centralized", "pve"],
                        help="Quick apply a predefined configuration preset")
    parser.add_argument("--meta", choices=["in-repo", "centralized"], help="Set metadata storage mode")
    parser.add_argument("--topology", choices=["local", "server"], help="Set execution topology")

    args = parser.parse_args()

    if args.status or (not args.preset and not args.meta and not args.topology):
        show_status()
        print("\nUsage Examples:")
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
