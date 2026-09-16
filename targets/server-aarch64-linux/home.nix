{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/neovim
    ../../home/shell/common.nix
    ../../home/tmux
  ];

  home.username = "ag";
  home.homeDirectory = "/home/ag";
  targets.genericLinux.enable = true;
}
