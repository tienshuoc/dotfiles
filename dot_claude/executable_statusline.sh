#!/bin/bash
# Combined Claude Code statusline.
#   line 1: user@host  cwd  (git-branch) | model | ctx <remaining>% | plugins
#   line 2: optional machine-specific status line extension
# Claude Code pipes a JSON blob to stdin. We read it once, use it for line 1,
# then forward it to the optional extension.

EXTRA_SCRIPT="$HOME/.config/agents/statusline-extra.sh"
SETTINGS="$HOME/.claude/settings.json"

INPUT=$(cat)
j() { printf '%s' "$INPUT" | jq -r "$1" 2>/dev/null; }

# --- palette (muted-by-default, one accent, semantic only where it carries meaning) ---
R="\033[0m"            # reset
B="\033[1m"            # bold (primary emphasis)
DIM="\033[2;37m"       # dim gray  - labels, separators, low-priority info
ACCENT="\033[36m"      # cyan      - single accent (identity: cwd, model)
VAL="\033[0;37m"       # light gray - data values
OK="\033[32m"; WARN="\033[33m"; CRIT="\033[31m"   # semantic stoplight (ctx health)
SEP=" ${DIM}│${R} "    # thin dim separator

# --- current directory (primary anchor) ---
CWD=$(j '.workspace.current_dir // .cwd // empty'); [ -z "$CWD" ] && CWD=$(pwd)

BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
GIT_PART=""
[ -n "$BRANCH" ] && GIT_PART=" ${DIM}(${R}${VAL}${BRANCH}${DIM})${R}"

# --- running subagents (hook-maintained list; hidden when none) ---
AGENTS_FILE="$HOME/.claude/running-agents.list"
AGENT_PART=""
if [ -s "$AGENTS_FILE" ]; then
    N=$(grep -c . "$AGENTS_FILE" 2>/dev/null)
    if [ "${N:-0}" -gt 0 ]; then
        TYPES=$(sort "$AGENTS_FILE" | uniq -c | awk '{t=$2; if($1>1)t=t"×"$1; printf "%s%s", sep, t; sep=","}')
        AGENT_PART="${DIM}agents${R} ${B}${N}${R} ${DIM}(${TYPES})${R}"
    fi
fi

# --- model (accent identity) + effort level ---
MODEL=$(j '.model.display_name // empty')
EFFORT=$(j '.effort.level // empty')
MODEL_PART=""
if [ -n "$MODEL" ]; then
    MODEL_PART="${SEP}${ACCENT}${MODEL}${R}"
    [ -n "$EFFORT" ] && MODEL_PART="${MODEL_PART} ${DIM}${EFFORT}${R}"
fi

# --- context remaining % before compression (semantic stoplight) ---
REMAIN=$(j '.context_window.remaining_percentage // empty')
CTX_PART=""
if [ -n "$REMAIN" ]; then
    P=${REMAIN%.*}                              # int part
    if   [ "$P" -le 15 ]; then CC="$CRIT"
    elif [ "$P" -le 30 ]; then CC="$WARN"
    else                       CC="$OK"; fi
    CTX_PART="${SEP}${DIM}ctx${R} ${CC}${P}%${R}"
fi

# --- token usage (input / output / cache hits) ---
fmt() { awk "BEGIN{n=$1; if(n>=1000) printf \"%.1fk\", n/1000; else printf \"%d\", n}"; }
IN=$(j '.context_window.current_usage.input_tokens // empty')
OUT=$(j '.context_window.current_usage.output_tokens // empty')
CACHE=$(j '.context_window.current_usage.cache_read_input_tokens // empty')
TOK_PART=""
if [ -n "$IN" ] || [ -n "$OUT" ] || [ -n "$CACHE" ]; then
    TOK_PART="${SEP}${DIM}in${R} ${VAL}$(fmt ${IN:-0})${R} ${DIM}out${R} ${VAL}$(fmt ${OUT:-0})${R} ${DIM}cache${R} ${VAL}$(fmt ${CACHE:-0})${R}"
fi

# --- enabled plugins (from settings.json, low priority) ---
PLUGINS=""
if [ -f "$SETTINGS" ]; then
    PLUGINS=$(jq -r '(.enabledPlugins // {}) | to_entries
        | map(select(.value == true) | (.key | split("@")[0]))
        | join(",")' "$SETTINGS" 2>/dev/null)
fi
PLUGIN_PART=""
[ -n "$PLUGINS" ] && PLUGIN_PART="${SEP}${DIM}${PLUGINS}${R}"

echo -e "${B}${ACCENT}${CWD}${R}${GIT_PART}${CTX_PART}${TOK_PART}${PLUGIN_PART}${MODEL_PART}"

# --- optional machine-specific status line extension ---
if [ -f "$EXTRA_SCRIPT" ]; then
    printf '%s' "$INPUT" | bash "$EXTRA_SCRIPT"
fi

# --- line 3: running subagents (only when any) ---
[ -n "$AGENT_PART" ] && echo -e "$AGENT_PART"

exit 0
