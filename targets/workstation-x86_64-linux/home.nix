{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/neovim
    ../../home/neovim/workstation.nix
    ../../home/shell/atuin.nix
    ../../home/shell/bash.nix
    ../../home/shell/bat.nix
    ../../home/shell/btop.nix
    ../../home/shell/fzf.nix
    ../../home/shell/starship.nix
    ../../home/shell/tools.nix
    ../../home/shell/zoxide.nix
    ../../home/terminal/ghostty.nix
    ../../home/tmux
    ../../home/tmux/workstation.nix
  ];

  home.username = "ag";
  home.homeDirectory = "/home/ag";
  targets.genericLinux.enable = true;
}
