# tmux wrapper shared by bash and zsh. Both shells source this file, so it uses
# only syntax valid in both.
#
# Why this exists: tmux turns on mouse and focus reporting in the outer
# terminal. While a reporting mode is on, the terminal sends an escape sequence
# to the program reading input for each mouse or focus event. A clean tmux exit
# turns these modes off. If tmux exits uncleanly (it is killed, crashes, or an
# SSH connection drops), the modes stay on, and the shell prompt receives the
# raw sequences as text, for example `^[[<35;80;20M` for mouse motion or
# `^[[I` and `^[[O` for focus changes. This wrapper turns the modes off every
# time tmux returns.

# Turn off the terminal modes that tmux can leave on.
#
# The sequences are DEC private mode resets (`CSI ? <mode> l`):
#   1000  report button presses and releases
#   1002  also report motion while a button is held (drag)
#   1003  also report all motion, even with no button held
#   1004  report focus in (`^[[I`) and focus out (`^[[O`)
#   1005  encode mouse coordinates as UTF-8
#   1006  encode mouse events in SGR form, such as `^[[<0;10;5M`
#   1015  encode mouse events in urxvt form
# Turning off a mode that is already off does nothing, so resetting all seven
# is safe after a clean exit too.
terminal_mouse_off() {
  # Act only in an interactive terminal outside tmux. Inside tmux, the
  # sequences would reach the enclosing tmux pane instead of the real terminal.
  [[ -t 0 && -z ${TMUX-} ]] || return 0
  # Write to the terminal device so redirected stdout cannot swallow the reset.
  builtin printf '\e[?1000l\e[?1002l\e[?1003l\e[?1004l\e[?1005l\e[?1006l\e[?1015l' > /dev/tty
}

# Run the real tmux, reset the terminal modes, and keep tmux's exit status.
tmux() {
  local rc=0
  command tmux "$@" || rc=$?
  terminal_mouse_off || :
  return "$rc"
}
