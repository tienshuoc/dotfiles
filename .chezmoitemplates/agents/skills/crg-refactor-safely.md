---
name: crg-refactor-safely
description: Plan or implement a requested refactor using code-review-graph dependency analysis. Use when graph tools can identify affected callers and tests.
metadata:
  requires: code-review-graph MCP tools for graph-assisted analysis
---

Keep the requested behavior and refactoring scope explicit.

- Start with `get_minimal_context` if available. Inspect dependencies and `get_impact_radius`.
- Use available `refactor_tool` modes to explore suggestions or preview a rename. Treat dead-code
  suggestions as candidates: dynamic references may be absent from the graph.
- Inspect a proposed edit set before applying it. Use `apply_refactor_tool` only when available
  and the user has authorized implementation; otherwise use the platform's normal editing tools.
- Inspect the resulting diff and run the tests relevant to the affected behavior.

Use only tools actually exposed by the current platform. Prefer minimal graph output and expand
when needed; there is no fixed tool-call budget. If graph tools are unavailable or incomplete,
continue with ordinary source inspection and state the limitation when it affects the result.
