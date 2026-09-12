// OpenCode plugin API: return hooks; do not call app.on().
// https://opencode.ai/docs/plugins/
export const CodeReviewGraph = async ({ $, worktree, directory }) => {
  const root = worktree || directory;
  const run = async (...args) => {
    try {
      await $`test -d ${root + "/.code-review-graph"}`.quiet();
      await $`code-review-graph ${args}`.cwd(root).quiet();
    } catch {
      // Missing tool/graph must not prevent editing or starting a session.
    }
  };
  return {
    event: async ({ event }) => {
      if (event.type === "file.edited") await run("update", "--skip-flows");
      if (event.type === "session.created") await run("status");
    },
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && /^\s*git\s+commit(?:\s|$)/.test(output.args.command || "")) {
        await run("detect-changes", "--brief");
      }
    },
  };
};
