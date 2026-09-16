{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/git/gh.nix
    ../../home/git/git.nix
    ../../home/neovim
    ../../home/shell/atuin.nix
    ../../home/shell/bash.nix
    ../../home/shell/bat.nix
    ../../home/shell/btop.nix
    ../../home/shell/fastfetch.nix
    ../../home/shell/fzf.nix
    ../../home/shell/starship.nix
    ../../home/shell/tools.nix
    ../../home/shell/zoxide.nix
    ../../home/ssh/ssh.nix
    ../../home/tmux
  ];

  home.username = "ag";
  home.homeDirectory = "/home/ag";
  targets.genericLinux.enable = true;
}
