# Dotfiles

My personal configuration, managed with chezmoi. It installs files into my home
directory and renders templates for settings that vary between machines.

## What's included

- Zsh, Oh My Zsh plugins, Powerlevel10k, and fzf configuration.
- Git, tmux, WezTerm, and herdr, with Zsh as herdr's default shell.
- Claude Code, Codex, and OpenCode settings, instructions, skills, and hooks.
- clangd and Karabiner configuration.
- Neovim from its [separate repository](https://github.com/tienshuoc/nvim).

## Set up a machine

Install Git, chezmoi, Zsh, Oh My Zsh, and the applications you use. Sign in to the
1Password CLI: the personal Zsh template reads its SambaNova API key from 1Password.
GitHub SSH access is needed for the repositories below.

```sh
chezmoi init git@github.com:tienshuoc/dotfiles.git
chezmoi diff
chezmoi apply
```

chezmoi also retrieves the Neovim configuration, shell plugins, and prompt theme
listed in `.chezmoiexternal.toml`.

For coding agents, follow [the agent setup guide](docs/agents.md), then run
`~/.local/bin/agent-setup`. Credentials, sessions, caches, and machine trust stay local.

## Make changes

Edit a managed file through chezmoi, review the result, and apply it:

```sh
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
```

Use `chezmoi cd` to enter the source repository, then review and commit changes
with Git. To start tracking an ordinary file, use `chezmoi add ~/.some-config`.

For shared agent instructions and skills, edit the template fragments below.
For Codex settings, edit `dot_codex/modify_private_config.toml`; it preserves local
state, so do not replace it with `chezmoi add ~/.codex/config.toml`.

## Find the source

| Location | Contents |
| --- | --- |
| `dot_zshrc.tmpl`, `dot_p10k.zsh`, `dot_fzf.zsh` | Shell and prompt |
| `dot_gitconfig`, `dot_tmux.conf`, `dot_wezterm.lua` | Git and terminals |
| `dot_config/` | Application configuration |
| `dot_claude/`, `dot_codex/`, `dot_agents/` | Agent settings and skill entrypoints |
| `.chezmoitemplates/agents/` | Shared instructions, skills, and settings fragments |
| `.chezmoiexternal.toml` | External repositories and archives |

chezmoi source names describe their destination: `dot_` becomes `.`, `.tmpl`
files are rendered, `executable_` sets executable permissions, and `private_`
restricts access. The README, guides, and tests stay in this repository.

## Personal and work

This repository is the personal base. A separate work repository keeps work-only
settings in one customization commit on top. Shared improvements go here first;
work instruction and settings fragments are filled in only in the work repository.

## Check agent configuration

```sh
python3 -B -m unittest discover -s tests
```

The tests use temporary homes and mocked commands; they do not change live settings.
