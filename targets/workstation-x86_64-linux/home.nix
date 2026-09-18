{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/ai/claude-code.nix
    ../../home/ai/codex.nix
    ../../home/ai/opencode.nix
    ../../home/ai/skills
    ../../home/desktop/apps.nix
    ../../home/desktop/gnome.nix
    ../../home/desktop/keyd.nix
    ../../home/desktop/wl-clipboard.nix
    ../../home/dev/cloudflare.nix
    ../../home/dev/go.nix
    ../../home/dev/js.nix
    ../../home/dev/rust.nix
    ../../home/dev/uv.nix
    ../../home/git/gh.nix
    ../../home/git/git.nix
    ../../home/neovim
    ../../home/neovim/workstation.nix
    ../../home/shell/atuin.nix
    ../../home/shell/bash.nix
    ../../home/shell/bat.nix
    ../../home/shell/btop.nix
    ../../home/shell/direnv.nix
    ../../home/shell/fastfetch.nix
    ../../home/shell/fzf.nix
    ../../home/shell/starship.nix
    ../../home/shell/tools.nix
    ../../home/shell/zoxide.nix
    ../../home/ssh/ssh.nix
    ../../home/terminal/ghostty.nix
    ../../home/tmux
    ../../home/tmux/workstation.nix
  ];

  # Print the machine summary when a terminal window opens (not per tmux pane).
  custom.fastfetch.greeting = true;

  custom.target = "workstation-x86_64-linux";
  home.username = "ag";
  home.homeDirectory = "/home/ag";
  targets.genericLinux.enable = true;
}
