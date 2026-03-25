#!/bin/zsh

# Pipe data to this function to copy it to clipboard (strips ANSI codes and trailing newline)
bb() {
    local data
    # Remove ANSI escape codes (colors, formatting)
    data=$(cat | sed $'s/\x1B\[[0-9;]*[a-zA-Z]//g')
    # Remove trailing newline
    data=${data%%$'\n'}
    # Send to clipboard via terminal escape sequence
    printf "\033]52;c;%s\a" "$(printf "%s" "$data" | base64 -w0)"
}