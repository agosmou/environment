# wl-clipboard: the Wayland clipboard from the shell. `copy` and `paste`
# aliases so the same words work on both machines; macOS binds them to
# pbcopy/pbpaste in home/shell/zsh.nix. Linux workstation only; a server has
# no clipboard.
#
#   $ some-command | copy
#   $ paste > file.txt
{ pkgs, ... }:

{
  home.packages = [ pkgs.wl-clipboard ];

  programs.bash.shellAliases = {
    copy = "wl-copy";
    paste = "wl-paste";
  };
}
