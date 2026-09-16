# zoxide: `cd` that remembers. `z proj` jumps to the most-used directory
# matching "proj"; `zi` picks from a list with fzf.
#
# Home Manager module: installs the binary and adds the hook to ~/.bashrc and
# ~/.zshrc that records every directory you cd into.
{ ... }:

{
  programs.zoxide.enable = true;
}
