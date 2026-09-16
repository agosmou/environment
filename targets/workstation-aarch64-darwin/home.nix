{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/neovim
    ../../home/neovim/workstation.nix
    ../../home/shell/common.nix
    ../../home/terminal/ghostty.nix
    ../../home/tmux
    ../../home/tmux/workstation.nix
  ];

  home.username = "ag";
  home.homeDirectory = "/Users/ag";
}
