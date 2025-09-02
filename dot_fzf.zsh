# Setup fzf
# ---------
if [[ ! "$PATH" == */home/tienshuoc/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/tienshuoc/.fzf/bin"
fi


export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

source <(fzf --zsh)
