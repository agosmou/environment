# shellcheck shell=bash
# (the line above tells shellcheck to lint this as bash; the file has no
# shebang because it is sourced by bash and zsh, never run directly)
#
# Shell functions shared by bash and zsh. Functions, not aliases, because
# they need arguments or more than one command.

# y: browse directories in yazi, and land in the one you picked.
#
# yazi is a terminal file manager: a two-pane view of the directory tree
# with file previews, driven by hjkl. This wraps it so that when you quit,
# your shell is in whatever directory you navigated to, which is the main
# reason to use a file manager from a shell at all.
#
# Usage:
#   y            open yazi in the current directory
#   y ~/src      open it somewhere else
#   (move around with hjkl, Enter to open, q to quit)
#   $ pwd        -> the directory you quit from
#
# Plain `yazi` still works but drops you back where you started.
y() {
  # Fail with a clear message instead of "command not found".
  command -v yazi >/dev/null || {
    printf 'y: yazi is not installed\n' >&2
    return 1
  }

  # A program cannot change its parent shell's directory, so yazi writes the
  # directory it ended in to a temp file and the shell reads it afterwards.
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  yazi "$@" --cwd-file="$tmp"

  # Only cd if yazi wrote something and it differs from where we already are.
  # `command cat` and `builtin cd` skip any alias or function of the same name.
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd" || return
  fi
  rm -f -- "$tmp"
}
