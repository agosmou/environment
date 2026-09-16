{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/ai/claude-code.nix
    ../../home/ai/codex.nix
    ../../home/ai/opencode.nix
    ../../home/ai/skills.nix
    ../../home/git/gh.nix
    ../../home/git/git.nix
    ../../home/neovim
    ../../home/neovim/workstation.nix
    ../../home/shell/atuin.nix
    ../../home/shell/bat.nix
    ../../home/shell/btop.nix
    ../../home/shell/fastfetch.nix
    ../../home/shell/fzf.nix
    ../../home/shell/starship.nix
    ../../home/shell/tools.nix
    ../../home/shell/zoxide.nix
    ../../home/shell/zsh.nix
    ../../home/ssh/ssh.nix
    ../../home/ssh/darwin.nix
    ../../home/terminal/ghostty.nix
    ../../home/tmux
    ../../home/tmux/workstation.nix
  ];

  # Print the machine summary when a terminal window opens (not per tmux pane).
  custom.fastfetch.greeting = true;

  custom.target = "workstation-aarch64-darwin";
  home.username = "ag";
  home.homeDirectory = "/Users/ag";
}
