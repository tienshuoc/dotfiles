# Setup fzf
# ---------
if [[ ! "$PATH" == */home/tienshuoc/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/tienshuoc/.fzf/bin"
fi


export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .cache --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Bazel + FZF Integration
_fzf_complete_bazel_test() {
    _fzf_complete '-m' "$@" < <(command bazel query \
        "kind('(test|test_suite) rule', //...)" 2>/dev/null)
}

_fzf_complete_bazel_build() {
    _fzf_complete '-m' "$@" < <(command bazel query \
        "kind('rule', //...) except kind('(test|test_suite) rule', //...)" 2>/dev/null)
}

_fzf_complete_bazel_run() {
    _fzf_complete '-m' "$@" < <(command bazel query \
        "kind('.*_binary rule', //...)" 2>/dev/null)
}

_fzf_complete_bazel() {
    local tokens
    tokens=($(printf "%s" "$LBUFFER" | xargs -n 1))

    if [ ${#tokens[@]} -ge 3 ]; then
        case "${tokens[2]}" in
        test)
            _fzf_complete_bazel_test "$@"
            ;;
        build)
            _fzf_complete_bazel_build "$@"
            ;;
        run)
            _fzf_complete_bazel_run "$@"
            ;;
        *)
            # Original completion for other commands
            _fzf_complete '-m' "$@" < <(command bazel query --keep_going \
                --noshow_progress \
                "kind('(binary rule)|(generated file)', deps(//...))" 2>/dev/null)
            ;;
        esac
    else
        # Original completion when no command specified
        _fzf_complete '-m' "$@" < <(command bazel query --keep_going \
            --noshow_progress \
            "kind('(binary rule)|(generated file)', deps(//...))" 2>/dev/null)
    fi
}

_fzf_complete_git_add() {
    _fzf_complete "-m --preview 'git diff --color=always {}'" "$@" < <(
    command git ls-files --modified --others --exclude-standard
)
}

_fzf_complete_git_restore() {
    _fzf_complete "-m --preview 'git diff --color=always {}'" "$@" < <(
    command git ls-files --modified
)
}

_fzf_complete_git_stash() {
    _fzf_complete "-m --preview 'git diff --color=always {}'" "$@" < <(
    command git ls-files --modified --others --exclude-standard
)
}

_fzf_complete_git() {
    local tokens
    tokens=($(printf "%s" "$LBUFFER" | xargs -n 1))

    if [ ${#tokens[@]} -ge 3 ]; then
        case "${tokens[2]}" in
        add)
            _fzf_complete_git_add "$@"
            ;;
        restore)
            _fzf_complete_git_restore "$@"
            ;;
        stash)
            _fzf_complete_git_stash "$@"
            ;;
        esac
    else
        # Original completion when no command specified
    fi
    _fzf_complete "$@"
}

source <(fzf --zsh)
