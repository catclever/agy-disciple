# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "mcp",
#     "pyyaml"
# ]
# ///

import os
import sys
import glob
import re
import yaml
from datetime import datetime
from pathlib import Path
from typing import Literal
from mcp.server.mcpserver import MCPServer

# Add scripts directory to sys.path for meta_resolver import
SCRIPTS_DIR = Path(__file__).resolve().parent.parent.parent / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.append(str(SCRIPTS_DIR))

try:
    import meta_resolver
except ImportError:
    meta_resolver = None

ScopeSearchEnum = Literal['active', 'grave', 'all']
ScopeRecordEnum = Literal['active', 'grave']

STOPWORDS = {
    "the", "and", "for", "with", "that", "this", "from", "into", "when", "where",
    "what", "which", "who", "whom", "whose", "why", "how", "are", "was", "were",
    "been", "being", "have", "has", "had", "having", "does", "did", "doing",
    "will", "would", "shall", "should", "can", "could", "may", "might", "must",
    "not", "but", "or", "nor", "yet", "so", "both", "either", "neither", "each",
    "every", "all", "any", "few", "more", "most", "other", "some", "such", "no",
    "own", "same", "than", "too", "very", "just", "now", "also", "only", "then",
    "use", "using", "used", "via", "file", "files", "code", "project", "new",
    "add", "added", "update", "updated", "fix", "fixed", "issue", "problem",
    "error", "anti", "pattern", "graveyard", "knowledge", "index", "base"
}

mcp = MCPServer("KnowledgeManager")


def resolve_project_kb_dir(project: str = "") -> tuple[str, str]:
    target = str(project).strip() if project and str(project).strip() else os.getcwd()

    # 1. Centralized check via meta_resolver
    if meta_resolver:
        try:
            meta_dir = meta_resolver.get_centralized_meta_dir(target)
            if meta_dir and os.path.exists(meta_dir):
                canonical_name = os.path.basename(meta_dir)
                kb_dir = os.path.join(meta_dir, "kb")
                os.makedirs(kb_dir, exist_ok=True)
                return canonical_name, kb_dir
        except Exception:
            pass

    # 2. In-Repo check
    p_path = Path(target).resolve()
    if not p_path.exists() and not p_path.is_absolute():
        p_path = Path.cwd() / target
    canonical_name = p_path.name
    kb_dir = p_path / "kb"
    kb_dir.mkdir(parents=True, exist_ok=True)
    return canonical_name, str(kb_dir)


def parse_frontmatter(content: str) -> tuple[dict, str]:
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)", content, re.DOTALL)
    if match:
        try:
            loaded = yaml.safe_load(match.group(1))
            if isinstance(loaded, dict):
                return loaded, match.group(2)
        except Exception:
            pass
    return {}, content


def format_frontmatter(metadata: dict, body: str) -> str:
    fm = yaml.dump(metadata, sort_keys=False, allow_unicode=True)
    body_str = body.strip()
    if body_str:
        return f"---\n{fm}---\n\n{body_str}\n"
    return f"---\n{fm}---\n"


def slugify_filename(raw_name: str, title: str = "") -> str:
    candidate = os.path.basename(str(raw_name).strip()) if raw_name else ""
    if candidate.lower().endswith(".md"):
        candidate = candidate[:-3]

    slug = re.sub(r"[^a-z0-9]+", "_", candidate.lower()).strip("_")
    if not slug and title:
        slug = re.sub(r"[^a-z0-9]+", "_", str(title).lower()).strip("_")

    if not slug or slug in {"knowledge", "grave"}:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        slug = f"kb_card_{timestamp}"

    return f"{slug}.md"


def extract_title_and_summary(file_path: str, content: str) -> tuple[str, str, str]:
    meta, body = parse_frontmatter(content)
    title = str(meta.get("title") or "").strip()
    summary = str(meta.get("description") or meta.get("summary") or "").strip()

    if not title:
        m = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
        if m:
            title = m.group(1).strip()
        else:
            title = os.path.basename(file_path).replace(".md", "")

    if not summary:
        for line in body.splitlines():
            s = line.strip()
            if s and not s.startswith("#") and not s.startswith("---"):
                summary = s[:200]
                break

    return title, summary, body


def collect_scope_files(kb_dir: str, scope: str, include_indexes: bool = False) -> list[tuple[str, str, str]]:
    entries = []
    if scope in ("active", "all") and os.path.exists(kb_dir):
        for path in sorted(glob.glob(os.path.join(kb_dir, "*.md"))):
            fname = os.path.basename(path)
            if not include_indexes and fname.lower() == "knowledge.md":
                continue
            entries.append(("active", fname, path))

    grave_dir = os.path.join(kb_dir, "graveyard")
    if scope in ("grave", "all") and os.path.exists(grave_dir):
        for path in sorted(glob.glob(os.path.join(grave_dir, "*.md"))):
            fname = os.path.basename(path)
            if not include_indexes and fname.lower() == "grave.md":
                continue
            entries.append(("grave", f"graveyard/{fname}", path))

    return entries


def extract_search_tokens(text: str) -> list[str]:
    q_lower = text.strip().lower()
    if not q_lower:
        return []
    tokens = [t for t in re.split(r"[\s,;:|/\\]+", q_lower) if t]
    return tokens


@mcp.tool()
def kb_search(
    project: str,
    query: str = "",
    scope: ScopeSearchEnum = 'all',
    limit: int = 5
) -> str:
    """Search the project's knowledge base and anti-pattern graveyard."""
    try:
        canonical_name, kb_dir = resolve_project_kb_dir(project)
    except ValueError as e:
        return f"Error: {e}"

    q_clean = (query or "").strip()
    max_results = max(1, int(limit or 5))

    if not q_clean or q_clean == "*":
        sections = [f"# Knowledge Base Overview [{canonical_name}] (scope: {scope})"]

        if scope in ("active", "all"):
            active_index = os.path.join(kb_dir, "knowledge.md")
            if os.path.exists(active_index):
                try:
                    with open(active_index, "r", encoding="utf-8") as f:
                        sections.append(f"## Active Index (knowledge.md)\n{f.read().strip()}")
                except Exception:
                    pass
            else:
                sections.append("## Active Index (knowledge.md)\n*(No knowledge.md index file found)*")

        if scope in ("grave", "all"):
            grave_index = os.path.join(kb_dir, "graveyard", "grave.md")
            if os.path.exists(grave_index):
                try:
                    with open(grave_index, "r", encoding="utf-8") as f:
                        sections.append(f"## Graveyard Index (graveyard/grave.md)\n{f.read().strip()}")
                except Exception:
                    pass
            else:
                sections.append("## Graveyard Index (graveyard/grave.md)\n*(No graveyard/grave.md index file found)*")

        all_files = collect_scope_files(kb_dir, scope, include_indexes=True)
        if all_files:
            file_lines = [f"- [{sc}] `{rel}`" for sc, rel, _ in all_files]
            sections.append("## Markdown Files in Scope\n" + "\n".join(file_lines))
        else:
            sections.append("## Markdown Files in Scope\n*(No markdown files found)*")

        return "\n\n".join(sections)

    q_lower = q_clean.lower()
    tokens = extract_search_tokens(q_clean)
    candidate_files = collect_scope_files(kb_dir, scope, include_indexes=True)

    scored_results = []
    for sc, rel_path, abs_path in candidate_files:
        try:
            with open(abs_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception:
            continue

        title, summary, body = extract_title_and_summary(abs_path, content)
        fname_lower = rel_path.lower()
        title_lower = title.lower()
        summary_lower = summary.lower()
        body_lower = body.lower()

        score = 0
        if q_lower in fname_lower:
            score += 10
        if q_lower in title_lower:
            score += 8
        if q_lower in summary_lower:
            score += 5
        if q_lower in body_lower:
            score += 3 * body_lower.count(q_lower)

        for tok in tokens:
            if len(tok) < 2 and tok != q_lower:
                continue
            if tok in fname_lower:
                score += 4
            if tok in title_lower:
                score += 3
            if tok in summary_lower:
                score += 2
            if tok in body_lower:
                score += body_lower.count(tok)

        if score > 0:
            matching_lines = []
            for line in body.splitlines():
                line_stripped = line.strip()
                if not line_stripped:
                    continue
                line_low = line_stripped.lower()
                if q_lower in line_low or any(t in line_low for t in tokens if len(t) >= 2 or t == q_lower):
                    matching_lines.append(line_stripped)
                if sum(len(x) for x in matching_lines) >= 300:
                    break

            snippet = " | ".join(matching_lines)[:300]
            if not snippet:
                snippet = (summary or body.strip().replace("\n", " "))[:300]

            scored_results.append((score, sc, rel_path, title, summary, snippet))

    if not scored_results:
        return f"No matching knowledge base documents found for query '{q_clean}' in project '{canonical_name}' (scope: {scope})."

    scored_results.sort(key=lambda x: (-x[0], x[2]))
    top_results = scored_results[:max_results]

    output_lines = [
        f"Found {len(scored_results)} matching document(s) in [{canonical_name}] for '{q_clean}' (showing top {len(top_results)}):"
    ]
    for score, sc, rel_path, title, summary, snippet in top_results:
        entry = f"- **[{sc}] `{rel_path}`** — {title} (score: {score})"
        if summary:
            entry += f"\n  Summary: {summary}"
        if snippet and snippet != summary:
            entry += f"\n  Snippet: {snippet}"
        output_lines.append(entry)

    return "\n\n".join(output_lines)


@mcp.tool()
def kb_read(project: str, path: str) -> str:
    """Reads a document from the project's knowledge base."""
    try:
        canonical_name, kb_dir = resolve_project_kb_dir(project)
    except ValueError as e:
        return f"Error: {e}"

    if not path or not str(path).strip():
        return "Error: Document path cannot be empty."

    clean_path = str(path).strip()
    while clean_path.startswith("./") or clean_path.startswith("kb/"):
        if clean_path.startswith("./"):
            clean_path = clean_path[2:]
        elif clean_path.startswith("kb/"):
            clean_path = clean_path[3:]
    clean_path = clean_path.lstrip("/")

    real_kb_dir = os.path.realpath(kb_dir)
    target_path = os.path.realpath(os.path.join(real_kb_dir, clean_path))

    if target_path != real_kb_dir and not target_path.startswith(real_kb_dir + os.sep):
        return f"Error: Path traversal rejected. '{path}' resolves outside the project knowledge base."

    if not os.path.exists(target_path) and not target_path.endswith(".md"):
        alt_path = target_path + ".md"
        if (alt_path == real_kb_dir or alt_path.startswith(real_kb_dir + os.sep)) and os.path.exists(alt_path):
            target_path = alt_path

    if not os.path.exists(target_path) or not os.path.isfile(target_path):
        return f"Error: Document '{clean_path}' not found in knowledge base for project '{canonical_name}' ({kb_dir})."

    try:
        with open(target_path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        return f"Error reading '{clean_path}': {e}"


@mcp.tool()
def kb_record(
    project: str,
    title: str,
    summary: str,
    content: str,
    scope: ScopeRecordEnum = 'active',
    filename: str = ''
) -> str:
    """Records a new document to the knowledge base or graveyard and synchronizes the index."""
    try:
        canonical_name, kb_dir = resolve_project_kb_dir(project)
    except ValueError as e:
        return f"Error: {e}"

    clean_title = (title or "").strip()
    clean_summary = (summary or "").strip()
    clean_content = (content or "").strip()

    if not clean_title:
        return "Error: 'title' cannot be empty."
    if not clean_summary:
        return "Error: 'summary' cannot be empty."
    if not clean_content:
        return "Error: 'content' cannot be empty."

    if scope == "grave":
        target_dir = os.path.join(kb_dir, "graveyard")
        index_path = os.path.join(target_dir, "grave.md")
        default_index_header = "# The Graveyard (Negative Knowledge Index)\n"
    else:
        target_dir = kb_dir
        index_path = os.path.join(kb_dir, "knowledge.md")
        default_index_header = "# Knowledge Base Index\n"

    os.makedirs(target_dir, exist_ok=True)

    card_filename = slugify_filename(filename, clean_title)
    card_path = os.path.join(target_dir, card_filename)

    existing_meta, body = parse_frontmatter(clean_content)
    meta = dict(existing_meta) if existing_meta else {}
    meta["title"] = clean_title
    meta["description"] = clean_summary
    meta["date"] = datetime.now().strftime("%Y-%m-%d")

    formatted_card = format_frontmatter(meta, body)
    with open(card_path, "w", encoding="utf-8") as f:
        f.write(formatted_card)

    bullet_line = f"- [{clean_title}]({card_filename}): {clean_summary}"
    if os.path.exists(index_path):
        with open(index_path, "r", encoding="utf-8") as f:
            index_lines = f.read().splitlines()
    else:
        index_lines = [default_index_header.strip(), ""]

    placeholder = "*No recorded anti-patterns or failed post-mortems yet.*"
    index_lines = [ln for ln in index_lines if ln.strip() != placeholder]

    link_pattern = re.compile(
        r"^\s*[-*]\s+.*\(\s*(?:\./)?" + re.escape(card_filename) + r"\s*\).*$"
    )
    updated_in_place = False
    for i, line in enumerate(index_lines):
        if link_pattern.match(line):
            index_lines[i] = bullet_line
            updated_in_place = True
            break

    if not updated_in_place:
        index_lines.append(bullet_line)

    temp_index_path = index_path + ".tmp"
    with open(temp_index_path, "w", encoding="utf-8") as f:
        f.write("\n".join(index_lines).rstrip() + "\n")
    os.replace(temp_index_path, index_path)

    rel_card = f"graveyard/{card_filename}" if scope == "grave" else card_filename
    rel_index = "graveyard/grave.md" if scope == "grave" else "knowledge.md"
    action_label = "updated in" if updated_in_place else "appended to"
    return (
        f"Successfully recorded [{canonical_name}] kb/{rel_card} "
        f"and {action_label} kb/{rel_index}."
    )


def extract_audit_keywords(text: str) -> set[str]:
    lower = text.lower()
    en_words = {
        w for w in re.findall(r"[a-z][a-z0-9_-]{2,}", lower)
        if w not in STOPWORDS
    }
    cjk_runs = set()
    for run in re.findall(r"[\u4e00-\u9fff]{2,}", lower):
        cjk_runs.add(run)
        for i in range(len(run) - 1):
            cjk_runs.add(run[i:i + 2])
    return en_words | cjk_runs


@mcp.tool()
def kb_audit(project: str, proposal: str) -> str:
    """Audits a technical proposal against known anti-patterns in the graveyard and active knowledge base."""
    try:
        canonical_name, kb_dir = resolve_project_kb_dir(project)
    except ValueError as e:
        return f"Error: {e}"

    clean_proposal = (proposal or "").strip()
    if not clean_proposal:
        return "Error: 'proposal' text cannot be empty."

    proposal_keywords = extract_audit_keywords(clean_proposal)

    grave_dir = os.path.join(kb_dir, "graveyard")
    grave_index_path = os.path.join(grave_dir, "grave.md")
    active_index_path = os.path.join(kb_dir, "knowledge.md")

    grave_index_content = ""
    if os.path.exists(grave_index_path):
        try:
            with open(grave_index_path, "r", encoding="utf-8") as f:
                grave_index_content = f.read().strip()
        except Exception:
            pass

    active_index_content = ""
    if os.path.exists(active_index_path):
        try:
            with open(active_index_path, "r", encoding="utf-8") as f:
                active_index_content = f.read().strip()
        except Exception:
            pass

    warnings = []
    grave_files = collect_scope_files(kb_dir, "grave", include_indexes=False)
    for _, rel_path, abs_path in grave_files:
        try:
            with open(abs_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception:
            continue

        title, summary, body = extract_title_and_summary(abs_path, content)
        doc_keywords = extract_audit_keywords(f"{title} {summary} {body}")
        matched = sorted(proposal_keywords & doc_keywords)
        title_summary_kw = extract_audit_keywords(f"{title} {summary}")
        high_signal_matches = sorted(proposal_keywords & title_summary_kw)

        if high_signal_matches or len(matched) >= 2:
            warnings.append(
                f"- **[GRAVEYARD MATCH] `{rel_path}` ({title})**\n"
                f"  Summary: {summary}\n"
                f"  Matched Keywords: {', '.join((high_signal_matches or matched)[:10])}"
            )

    if grave_index_content:
        for line in grave_index_content.splitlines():
            s = line.strip()
            if not s.startswith(("-", "*")):
                continue
            line_kw = extract_audit_keywords(s)
            overlap = sorted(proposal_keywords & line_kw)
            if overlap and not any(s in w for w in warnings):
                warnings.append(
                    f"- **[GRAVEYARD INDEX MATCH]** {s}\n"
                    f"  Matched Keywords: {', '.join(overlap[:10])}"
                )

    active_matches = []
    active_files = collect_scope_files(kb_dir, "active", include_indexes=False)
    for _, rel_path, abs_path in active_files:
        try:
            with open(abs_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception:
            continue
        title, summary, body = extract_title_and_summary(abs_path, content)
        title_summary_kw = extract_audit_keywords(f"{title} {summary}")
        overlap = sorted(proposal_keywords & title_summary_kw)
        if overlap:
            active_matches.append(
                f"- **`{rel_path}` ({title})**: {summary} (Matched: {', '.join(overlap[:8])})"
            )

    report = [f"# Knowledge Base Audit Report [{canonical_name}]"]
    if warnings:
        report.append(
            "## ⚠️ Potential Graveyard Anti-Pattern Warnings\n"
            "The following graveyard records share keywords/concepts with your proposal. "
            "Verify your design does not repeat these failures:\n\n" + "\n".join(warnings)
        )
    else:
        report.append(
            "## ✅ No Direct Graveyard Anti-Pattern Conflicts Detected\n"
            "No direct keyword conflicts matched against recorded graveyard post-mortems."
        )

    if active_matches:
        report.append(
            "## 📌 Relevant Active Architectural Constraints\n" + "\n".join(active_matches)
        )

    if grave_index_content:
        report.append(f"## Graveyard Index Summary (`graveyard/grave.md`)\n{grave_index_content}")
    else:
        report.append("## Graveyard Index Summary (`graveyard/grave.md`)\n*(No graveyard index found)*")

    if active_index_content:
        report.append(f"## Active Knowledge Index Summary (`knowledge.md`)\n{active_index_content}")

    return "\n\n".join(report)


if __name__ == "__main__":
    mcp.run()
