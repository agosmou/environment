{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/desktop/macos.nix
    ../../home/ai/claude-code.nix
    ../../home/ai/codex.nix
    ../../home/ai/opencode.nix
    ../../home/ai/skills
    ../../home/dev/cloudflare.nix
    ../../home/dev/go.nix
    ../../home/dev/js.nix
    ../../home/dev/rust.nix
    ../../home/dev/uv.nix
    ../../home/dev/xcode.nix
    ../../home/git/gh.nix
    ../../home/git/git.nix
    ../../home/neovim
    ../../home/neovim/workstation.nix
    ../../home/shell/atuin.nix
    ../../home/shell/bat.nix
    ../../home/shell/btop.nix
    ../../home/shell/direnv.nix
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
  # The account on the Mac mini. Home Manager refuses to activate under any
  # other user, so this must match `whoami` there.
  home.username = "agomez";
  home.homeDirectory = "/Users/agomez";
}
