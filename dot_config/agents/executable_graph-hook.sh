#!/usr/bin/env bash
# Native hook adapters call this only for status/update; graphs are project-local.
cat >/dev/null
command -v code-review-graph >/dev/null 2>&1 || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[[ -d "$root/.code-review-graph" ]] || exit 0
cd "$root" || exit 0
case "${1:-}" in
  status) code-review-graph status || true ;;
  update) code-review-graph update --skip-flows || true ;;
esac
