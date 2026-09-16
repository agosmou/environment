{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/neovim
    ../../home/shell/atuin.nix
    ../../home/shell/bash.nix
    ../../home/shell/bat.nix
    ../../home/shell/btop.nix
    ../../home/shell/fzf.nix
    ../../home/shell/starship.nix
    ../../home/shell/tools.nix
    ../../home/shell/zoxide.nix
    ../../home/tmux
  ];

  home.username = "ag";
  home.homeDirectory = "/home/ag";
  targets.genericLinux.enable = true;
}
