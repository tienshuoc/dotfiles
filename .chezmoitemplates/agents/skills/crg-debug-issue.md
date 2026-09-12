---
name: crg-debug-issue
description: Trace a reported defect using code-review-graph callers, flows, and recent changes. Use when graph navigation can help investigate the reported behavior.
metadata:
  requires: code-review-graph MCP tools for graph-assisted analysis
---

Start with the reported symptom and a reproducible observation when available.

- Use `get_minimal_context` if available, then search for the affected symbols.
- Follow callers and execution paths with `query_graph` and available flow tools.
- Use `detect_changes` when a regression is suspected; recent changes are evidence to investigate,
  not proof of the cause.
- Inspect source and relevant tests to distinguish hypotheses. Implement a fix only within the
  user's requested scope, and verify the previously failing behavior where practical.

Use only tools actually exposed by the current platform. Prefer minimal graph output and expand
when needed; there is no fixed tool-call budget. If graph tools are unavailable or incomplete,
continue with ordinary source inspection and state the limitation when it affects the result.
