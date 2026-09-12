---
name: crg-explore-codebase
description: Explore repository architecture and code relationships using code-review-graph. Use for code-navigation questions when a graph covers the repository.
metadata:
  requires: code-review-graph MCP tools for graph-assisted analysis
---

Choose the smallest graph query that answers the user's question.

- Start with `get_minimal_context` if available.
- For orientation, use `get_architecture_overview` and relevant communities.
- For a symbol, use `semantic_search_nodes`, then `query_graph` relationships such as
  `callers_of`, `callees_of`, or `imports_of`.
- For execution paths, use the available flow tools and inspect key source locations.
- Explain the relevant relationships with concrete file references; avoid dumping the entire graph.

Use only tools actually exposed by the current platform. Prefer minimal graph output and expand
when needed; there is no fixed tool-call budget. If graph tools are unavailable or incomplete,
continue with ordinary source inspection and state the limitation when it affects the result.
