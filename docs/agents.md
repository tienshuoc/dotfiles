# Coding agent configuration

chezmoi owns the authored configuration for Claude Code, Codex, and OpenCode.
Installed targets are regular files. Keep account credentials, sessions, automatic
memories, plugin caches, and machine trust decisions local.

## Editing

| Content | Edit in the source repository |
| --- | --- |
| Shared global instructions | `.chezmoitemplates/agents/instructions/common.md` |
| Shared graph skills | `.chezmoitemplates/agents/skills/crg-*.md` |
| Claude preferences and hooks | `.chezmoitemplates/agents/claude-settings-base.json`, `dot_claude/hooks/` |
| Codex preferences | `dot_codex/modify_private_config.toml` |
| Codex hooks | `dot_codex/hooks.json` |
| OpenCode configuration | `dot_config/opencode/opencode.json`, `tui.json` |
| OpenCode graph integration | `dot_config/opencode/plugins/crg-plugin.js` |
| Graph lifecycle helper | `dot_config/agents/executable_graph-hook.sh` |
| Tool version baseline | `.chezmoidata/agents.toml` |

The global instruction files and two skill installations render from common
templates. Edit the shared source rather than the small wrappers. The empty work
instruction/settings/setup fragments are extension points for the work repository.
Do not put private work content into the personal base behind a conditional.

Keep repository build commands and architecture in that repository's context files.
A repository `CLAUDE.md` can import `@AGENTS.md` when sharing project instructions
with Codex and OpenCode. This migration does not rewrite project context files.

## Skills

Four portable skills replace the previous flat Markdown files under Claude's
skills directory: `crg-review-changes`, `crg-refactor-safely`,
`crg-explore-codebase`, and `crg-debug-issue`. Each has a lowercase name and a
`SKILL.md` entrypoint. They use graph tools when available and fall back to source
inspection when graph coverage is unavailable. They impose no fixed call budget.

Claude reads its generated copies under `~/.claude/skills`. Codex and OpenCode
read `~/.agents/skills`. Zsh exports `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` so
OpenCode does not load both copies. Set that variable in other launch environments
too. The work Bash configuration also sets it. This disables OpenCode's discovery
of project `.claude/skills`; keep cross-tool project skills in `.agents/skills`.

Built-in and plugin-provided skills remain owned by their platform/plugin manager.
Do not copy them out of plugin caches into this repository.

## Restore

1. Install the desired CLIs, Python 3, Node, jq, Git, and uv or pipx. The Python
   hooks use `fcntl` and support Linux/macOS.
2. Review `chezmoi diff`, then run `chezmoi apply`.
3. Run `~/.local/bin/agent-setup`. This is an explicit restore command, not a hook
   that installs packages during every apply. It installs code-review-graph 2.3.8
   if missing, preserves an already installed version, registers the user-scoped
   Claude graph MCP if missing, and installs missing selected Claude plugins.
4. Connect account-backed Codex plugins through `/plugins`. Login credentials and
   connector grants cannot be restored by copying a cache.
5. Start fresh CLI sessions and check native instruction/skill discovery. Review
   Codex hook trust when prompted; hook trust hashes are intentionally not seeded.

The personal Claude selection is Caveman and clangd. Their upstream marketplaces
are declared in settings. Caveman auto-update remains enabled as in the original
setup; plugin versions are manager-owned, not locked by copying cache directories.
The selected code-review-graph version is a restore baseline, not an automatic
downgrade of an existing installation.

The Codex bundles observed during migration were Atlassian Rovo, Codex Security,
Deep Research Work, GitHub, Gmail, Google Calendar, Google Drive, OpenAI Templates,
Plugin Management, and Workspace Agents. Cache presence is an inventory, not a
declaration that every bundle was enabled. Select the desired connections for the
account in use.

Use native plugin installation to restore upstream functionality. Do not run
`code-review-graph install --platform ...` over these managed files: its installer
writes configuration that is now owned here. Build a project graph explicitly
when needed; lifecycle hooks only update an existing graph.

## Ownership of mixed files

Codex's `modify_private_config.toml` owns selected preferences and graph MCP
settings while preserving unrelated values, including `projects`, `hooks.state`,
and UI counters. It uses chezmoi's built-in `chezmoi:modify-template` directive;
the source filename deliberately has no `.tmpl` suffix. TOML serialization can
reformat the file when a managed value changes. If managed values already match,
the current bytes pass through unchanged, including comments and newly written
local state.

Do not run `chezmoi add ~/.codex/config.toml`: it would replace the partial-file
source with a copy of the mixed runtime file. Edit the modify template instead.
Unmanaged entries are preserved, so applying personal configuration is not a
cleanup operation that removes existing work entries from a machine.

Claude settings are fully managed after removing literal credentials. Deliberate
changes made through its UI/plugin commands should be reviewed and incorporated
into the source. Keep `settings.local.json` and accumulated local approvals local.
The restore command only owns the named graph MCP entry in `~/.claude.json`; the
whole account/project registry is not tracked.

The old standalone Caveman and shell tracking hooks remain on disk but are no
longer registered by the proposed configuration. Caveman's installed plugin owns
its lifecycle hooks. The portable Python tracking hook preserves the existing
running-agent list behavior. The list remains shared across sessions,
matching the previous behavior; it is a status hint, not a task scheduler.

The OpenCode graph plugin uses the native hooks-object API and needs no npm
dependencies. Existing local `node_modules` and lockfiles are left alone. Only
the superseded `crg-plugin.ts` and four flat skill files are removed on apply,
through explicit entries in `.chezmoiremove`.

## Verification

Run `python3 -B -m unittest discover -s tests` from either checkout. It renders into a temporary
home, checks partial-file preservation and idempotence, and exercises hooks and
restore behavior using synthetic data and mocked external commands. It does not
apply to the real home or contact an LLM.

References: [shared chezmoi templates](https://www.chezmoi.io/reference/special-directories/chezmoitemplates/),
[partial-file management](https://www.chezmoi.io/user-guide/manage-different-types-of-file/#manage-part-but-not-all-of-a-file),
[Codex skill discovery](https://learn.chatgpt.com/docs/build-skills),
[Claude skills](https://code.claude.com/docs/en/skills),
[OpenCode compatibility controls](https://opencode.ai/docs/rules/),
[OpenCode plugin API](https://opencode.ai/docs/plugins/).
