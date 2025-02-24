# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="my_theme"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=~/dotfiles/zsh/ZSH_CUSTOM

####################################################### PLUGINS (begin) ###########################################################
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    git-prompt
    you-should-use
    # Ctrl-o to copy the current text in the command line to the system clipboard.
    copybuffer
    # Keyboard shortcuts for navigating directory history and hierarchy.
    dirhistory
)

# You-Should-Use Configs
export YSU_IGNORED_ALIASES=("g" "ll")

# Install instructions: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
# source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
if [ -x "$(command -v brew)" ]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh  # MacOs
fi

# Install: git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
# source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
if [ -x "$(command -v brew)" ]; then
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh  # MacOS
fi

# TODO: Move this out into a fzf config file.
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
####################################################### PLUGINS (end) ###########################################################

####################################################### FUNCTIONS (begin) ###########################################################
source $ZSH_CUSTOM/scripts/my_functions.sh
####################################################### FUNCTIONS (end) ###########################################################

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='nvim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR='nvim'

####################################################### ALIASES (begin) ###########################################################
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.

alias grep='grep --color=always'

alias tmux="tmux -2" # Force TMUX to recognize 256 colors.
alias ta="tmux at"
alias tl="tmux ls"

alias ls='ls --color'
alias ll='ls -lF'
alias lla='ls -alF'
alias llt='ls -talF'
alias llr='echo "Most recent 10." && ls -tlF | head -n10'

alias findfile='find . | rg -i'

# Open Vim sessions.
alias vs1='nvim -S ~/s1.vim'
alias vs2='nvim -S ~/s2.vim'
alias vs3='nvim -S ~/s3.vim'
alias vs4='nvim -S ~/s4.vim'

alias dv='dirs -v'
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

### >> Project Specific (begin)
export PROJECT_ROOT="~/kosmos"
### << Project Specific (end)

alias ozrc="$EDITOR ~/.zshrc"
alias szrc='source ~/.zshrc'
alias gtmr='cd $(ls --color=no -td -- */ | head -n 1)'
# alias gtdf='cd ~/dotfiles'
alias gtnv='cd ~/.config/nvim'
alias gtpr="cd $PROJECT_ROOT"
alias oprf='gtpr && fzf -i --bind "enter:become($EDITOR {})"'
alias oprd='gtpr && cd $(find . -type d -print | fzf -i)'
alias gam='function _gam() { git commit -am "$*"; }; _gam'
alias gm='function _gm() { git commit -m "$*"; }; _gm'

# Extract all directories under current directory and enter the latest extracted directory.
alias tart='find . -type f -name "*.tar.gz" -exec tar -xvf {} \; > /dev/null 2>&1 && echo "tar done!"'
#alias tart='find . -type f -name "*.tar.gz" -exec tar -xvf {} \; && cd "$(find . -maxdepth 1 -type d | sort -r | head -n 1)"'
####################################################### ALIASES (end) ###########################################################

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.fzf/shell/key-bindings.zsh ] && source ~/.fzf/shell/key-bindings.zsh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export REACT_EDITOR=nvim
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

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
