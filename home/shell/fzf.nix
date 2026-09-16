# fzf: fuzzy finder. Ctrl-T inserts a file path, Alt-C cds into a directory,
# and other tools (the tmux session picker, Neovim) call it for their lists.
#
# Home Manager module: installs the binary and adds the key-binding hook to
# ~/.bashrc and ~/.zshrc.
{ ... }:

{
  programs.fzf = {
    enable = true;
    # fzf's own Ctrl-R history search. Empty string disables it because atuin
    # owns Ctrl-R; any shell command here would replace fzf's default.
    historyWidget.command = "";
  };
}
