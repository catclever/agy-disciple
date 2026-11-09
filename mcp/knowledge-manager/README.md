# Knowledge Manager FastMCP Server

A standalone FastMCP server providing structured project knowledge base management and anti-pattern graveyard auditing for Google Antigravity.

## Features

- **`kb_search(project, query, scope, limit)`**: Search active project knowledge cards, anti-pattern graveyard records, or view index summaries.
- **`kb_read(project, path)`**: Safely read a specific knowledge document with path-traversal prevention.
- **`kb_record(project, title, summary, content, scope, filename)`**: Automatically save markdown knowledge documents with formatted YAML Frontmatter and synchronize `knowledge.md` or `graveyard/grave.md` index files.
- **`kb_audit(project, proposal)`**: Pre-presentation design audit against known anti-patterns in the graveyard (supports English and CJK keyword analysis).

## Integration in Antigravity

Configure in `~/.gemini/antigravity/mcp_config.json` (or workspace MCP settings):

```json
{
  "mcpServers": {
    "knowledge-manager": {
      "command": "uv",
      "args": [
        "run",
        "--with",
        "mcp",
        "--with",
        "pyyaml",
        "/path/to/agy-disciple/mcp/knowledge-manager/server.py"
      ]
    }
  }
}
```
