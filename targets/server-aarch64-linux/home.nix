{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/ai/claude-code.nix
    ../../home/ai/codex.nix
    ../../home/ai/opencode.nix
    ../../home/ai/skills
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

  custom.target = "server-aarch64-linux";
  home.username = "ag";
  home.homeDirectory = "/home/ag";
  targets.genericLinux.enable = true;
}
