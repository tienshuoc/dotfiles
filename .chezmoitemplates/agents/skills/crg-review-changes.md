---
name: crg-review-changes
description: Review code changes with code-review-graph impact and test-coverage analysis. Use for a requested review when graph tools are available.
metadata:
  requires: code-review-graph MCP tools for graph-assisted analysis
---

Use the requested diff or commit range as the review boundary. Keep this workflow read-only.

- Start with `get_minimal_context` if available, then `detect_changes` for the selected changes.
- Use `get_affected_flows` and `get_impact_radius` where changed behavior can affect callers.
- Use `query_graph` with `tests_for` to find relevant coverage, then inspect implementation and tests.
- Report actionable defects with file locations and evidence. Distinguish observed failures from
  missing coverage or unverified concerns. Do not infer correctness from a graph risk score.

Use only tools actually exposed by the current platform. Prefer minimal graph output and expand
when needed; there is no fixed tool-call budget. If graph tools are unavailable or incomplete,
continue with ordinary source inspection and state the limitation when it affects the result.
