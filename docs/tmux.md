# tmux

Home Manager writes `~/.config/tmux/tmux.conf` from `home/tmux/default.nix`.
Plugins are Nix-pinned and loaded from there; there is no TPM. The status bar
and the session picker need a Nerd Font in the terminal (Ghostty has one).

## Keys

Prefix is `Ctrl-Space`.

| Key | Does |
|---|---|
| `prefix r` | Reload the config |
| `prefix c` | New window, in the current directory |
| `prefix \|` / `prefix -` | Split right / below, in the current directory |
| `Ctrl-h/j/k/l` | Move between panes, and Neovim splits, as one space |
| `prefix H/J/K/L` | Resize the pane (repeatable) |
| `prefix s` | Session picker (sesh): `Ctrl-t` tmux sessions, `Ctrl-x` zoxide directories, `Ctrl-a` all |
| `prefix Ctrl-s` / `prefix Ctrl-r` | Save / restore the session layout (resurrect) |
| Mouse | Select and scroll; double- and triple-click copy a word or line |

Copy mode is vi-style: `prefix [` to enter, `v` to select, `y` to copy.

## Behaviour

- Windows and panes number from 1; closing one renumbers the rest.
- 100,000 lines of scrollback.
- Sessions are saved every 15 minutes and restored when the tmux server
  starts (continuum), to `~/.local/share/tmux/resurrect`. Layouts, paths, and
  running commands come back; process memory and unsaved buffers do not.
- Status bar: everforest theme (tmux-power); CPU and RAM only when the window
  is wider than 180 columns; battery and online status on workstations
  (`custom.tmux.laptopWidgets`, set in the workstation targets).
