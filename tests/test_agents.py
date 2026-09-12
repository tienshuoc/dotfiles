#!/usr/bin/env python3
"""Verify agent dotfiles in an isolated home; no live installs or model calls."""
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest


class AgentDotfiles(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = Path(__file__).resolve().parents[1]
        cls.temp = tempfile.TemporaryDirectory(prefix="agent-dotfiles-test-")
        cls.root = Path(cls.temp.name)
        cls.home = cls.root / "home with spaces"
        cls.home.mkdir()
        for rel in [".config/opencode/plugins", ".codex", ".local/bin", "bin", ".claude/skills/mine"]:
            (cls.home / rel).mkdir(parents=True)
        cls.original = {
            "model": "old-model",
            "projects": {"/example/project": {"trust_level": "trusted"}},
            "hooks": {"state": {"example": {"trusted_hash": "keep-me"}}},
            "tui": {"model_availability_nux": {"example": 4}},
            "mcp_servers": {"other": {"command": "keep-this-server"}},
        }
        (cls.home / ".codex/config.toml").write_text('''model = "old-model"
[projects."/example/project"]
trust_level = "trusted"
[hooks.state.example]
trusted_hash = "keep-me"
[tui.model_availability_nux]
example = 4
[mcp_servers.other]
command = "keep-this-server"
''')
        (cls.home / ".claude/skills/review-changes.md").write_text("superseded")
        (cls.home / ".claude/skills/mine/SKILL.md").write_text("unmanaged skill")
        (cls.home / ".config/opencode/plugins/crg-plugin.ts").write_text("superseded")
        cls.config = cls.root / "chezmoi.toml"
        cls.config.write_text('''[data]
workHome = "/example/storage"
dumpRoot = "/example/dumps"
personalSourceDir = "/example/personal"
agentMarketplaceDir = ''' + json.dumps(str(cls.root / "marketplace")) + "\n")
        cls.command = [shutil.which("chezmoi") or str(Path.home()/"bin/chezmoi"),
                       "--source", str(cls.source), "--destination", str(cls.home),
                       "--config", str(cls.config), "--persistent-state", str(cls.root / "state.boltdb"),
                       "--exclude", "externals,scripts"]
        cls.targets = [".agents", ".claude", ".codex", ".config/agents", ".config/opencode", ".local/bin/agent-setup"]
        cls.work = (cls.source / "bin/executable_withjenkins").exists()
        if cls.work:
            cls.targets.append("bin/withjenkins")
        cls.apply()
        cls.env = {**os.environ, "HOME": str(cls.home)}
        cls.env.pop("CLAUDE_CONFIG_DIR", None)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def apply(cls):
        subprocess.run(cls.command + ["apply", "--force", *[str(cls.home / p) for p in cls.targets]],
                       check=True, capture_output=True, text=True, timeout=30)

    def test_partial_config_preserves_state(self):
        config = tomllib.loads((self.home / ".codex/config.toml").read_text())
        self.assertEqual(config["model"], "gpt-6-astra")
        self.assertEqual(config["projects"], self.original["projects"])
        self.assertEqual(config["hooks"], self.original["hooks"])
        self.assertEqual(config["tui"]["model_availability_nux"], {"example": 4})
        self.assertEqual(config["mcp_servers"]["other"], {"command": "keep-this-server"})
        self.assertEqual(config["mcp_servers"]["code-review-graph"]["args"], ["serve"])

    def test_idempotent_render_and_targeted_removal(self):
        before = (self.home / ".codex/config.toml").read_bytes()
        self.apply()
        self.assertEqual((self.home / ".codex/config.toml").read_bytes(), before)
        self.assertFalse((self.home / ".claude/skills/review-changes.md").exists())
        self.assertFalse((self.home / ".config/opencode/plugins/crg-plugin.ts").exists())
        self.assertTrue((self.home / ".claude/skills/mine/SKILL.md").exists())
        result = subprocess.run(self.command + ["diff", "--no-pager", *[str(self.home / p) for p in self.targets]],
                                check=True, capture_output=True, text=True)
        self.assertEqual(result.stdout, "")

    def test_shared_instructions_skills_and_settings(self):
        content = [(self.home / p).read_text().strip() for p in
                   [".claude/CLAUDE.md", ".codex/AGENTS.md", ".config/opencode/AGENTS.md"]]
        self.assertEqual(len(set(content)), 1)
        self.assertEqual("withjenkins" in content[0], self.work)
        self.assertEqual("Create pull requests as drafts" in content[0], self.work)
        skills = sorted((self.home / ".agents/skills").glob("*/SKILL.md"))
        self.assertEqual(len(skills), 4)
        for skill in skills:
            self.assertEqual(skill.read_bytes(), (self.home / ".claude/skills" / skill.parent.name / "SKILL.md").read_bytes())
        settings = json.loads((self.home / ".claude/settings.json").read_text())
        self.assertFalse(any(name.endswith(("_TOKEN", "_KEY")) for name in settings.get("env", {})))
        self.assertEqual("apiKeyHelper" in settings, self.work)
        self.assertNotIn("caveman-activate.js", json.dumps(settings["hooks"]))
        self.assertEqual(len(settings["hooks"]["PreToolUse"]), 1 + int(self.work))
        self.assertEqual("gh-pr-draft.py" in json.dumps(settings["hooks"]), self.work)
        self.assertEqual("UserPromptSubmit" in settings["hooks"], self.work)

    def test_tracking_hook(self):
        hook = self.home / ".claude/hooks/agent-track.py"
        for mode in ["reset", "start", "start", "stop"]:
            subprocess.run(["python3", str(hook), mode], input='{"tool_input":{"subagent_type":"explore"}}',
                           env=self.env, text=True, capture_output=True, check=True)
        self.assertEqual((self.home / ".claude/running-agents.list").read_text(), "explore\n")

    def test_preserves_runtime_formatting(self):
        target = self.home / ".codex/config.toml"
        edited = "# Added by a local application\n" + target.read_text() + "\n[local_runtime]\nnew_counter = 7\n"
        target.write_text(edited)
        self.apply()
        self.assertEqual(target.read_text(), edited)

    def test_restore_is_idempotent(self):
        mock = self.root / "mock-bin"
        mock.mkdir(exist_ok=True)
        state = self.root / "mock-state.json"
        state.write_text(json.dumps({"marketplaces": [], "plugins": [], "writes": []}))
        stub = '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
p = Path(os.environ["MOCK_AGENT_STATE"])
s = json.loads(p.read_text()); args = sys.argv[1:]; name = Path(sys.argv[0]).name
if name == "code-review-graph":
    print("code-review-graph 2.3.8")
elif name == "claude":
    if args[:3] == ["plugin", "marketplace", "list"]: print(json.dumps(s["marketplaces"]))
    elif args[:2] == ["plugin", "list"]: print(json.dumps(s["plugins"]))
    else:
        s["writes"].append(args)
        if args[:2] == ["mcp", "add"]:
            q = Path.home()/".claude.json"; d = json.loads(q.read_text()) if q.exists() else {}
            d.setdefault("mcpServers", {})["code-review-graph"] = {"command":"code-review-graph","args":["serve"]}
            q.write_text(json.dumps(d))
        elif args[:3] == ["plugin", "marketplace", "add"]:
            source=args[3]
            settings = json.loads((Path.home()/".claude/settings.json").read_text())
            name = next(name for name,entry in settings["extraKnownMarketplaces"].items()
                        if source in entry["source"].values())
            s["marketplaces"].append({"name":name})
        elif args[:2] == ["plugin", "install"]: s["plugins"].append({"id":args[-1],"scope":"user"})
        p.write_text(json.dumps(s))
elif name == "git" and args[:1] == ["clone"]:
    Path(args[-1]).mkdir(parents=True)
'''
        for name in ["claude", "code-review-graph", "git", "node", "jq"]:
            path = mock/name; path.write_text(stub); path.chmod(0o755)
        registry = self.home / ".claude.json"
        registry.write_text('{"unrelated":"keep-me"}')
        env = {**self.env, "PATH": str(mock)+os.pathsep+os.environ["PATH"], "MOCK_AGENT_STATE": str(state)}
        setup = self.home/".local/bin/agent-setup"
        subprocess.run([str(setup)], env=env, capture_output=True, text=True, check=True)
        first = json.loads(state.read_text())["writes"]
        self.assertTrue(first)
        subprocess.run([str(setup)], env=env, capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(state.read_text())["writes"], first)
        self.assertEqual(json.loads(registry.read_text())["unrelated"], "keep-me")

    def test_opencode_plugin_contract(self):
        if not shutil.which("node"):
            self.skipTest("node not installed")
        code = (self.home / ".config/opencode/plugins/crg-plugin.js").read_bytes()
        url = "data:text/javascript;base64," + base64.b64encode(code).decode()
        test = '''
import assert from 'node:assert/strict';
const {CodeReviewGraph} = await import(URL);
const calls = [];
let fail = false;
const $ = (strings, ...values) => ({
  cwd(root) { assert.equal(root, '/example/repo'); return this; },
  async quiet() { if (fail) throw Error('missing graph'); calls.push({strings, values}); return {}; }
});
const hooks = await CodeReviewGraph({$, worktree:'/example/repo', directory:'/example/repo/subdir'});
await hooks.event({event:{type:'session.created'}});
await hooks.event({event:{type:'file.edited'}});
await hooks['tool.execute.before']({tool:'bash'}, {args:{command:'git commit -m test'}});
assert.deepEqual(calls.filter(x=>x.strings[0]==='code-review-graph ').map(x=>x.values[0]),
                 [['status'],['update','--skip-flows'],['detect-changes','--brief']]);
const count = calls.length;
await hooks.event({event:{type:'unrelated'}});
await hooks['tool.execute.before']({tool:'read'}, {args:{}});
assert.equal(calls.length, count);
fail = true;
await hooks.event({event:{type:'file.edited'}});
'''.replace("URL", json.dumps(url))
        subprocess.run(["node", "--input-type=module", "-e", test], capture_output=True, text=True, check=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
