{ ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/ai/claude-code.nix
    ../../home/ai/codex.nix
    ../../home/ai/opencode.nix
    ../../home/ai/skills
    ../../home/dev/cloudflare.nix
    ../../home/dev/go.nix
    ../../home/dev/js.nix
    ../../home/dev/rust.nix
    ../../home/dev/uv.nix
    ../../home/git/gh.nix
    ../../home/git/git.nix
    ../../home/neovim
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
    ../../home/tmux
  ];

  custom.target = "server-x86_64-linux";
  home.username = "ag";
  home.homeDirectory = "/home/ag";
  targets.genericLinux.enable = true;
  # genericLinux pulls a Mesa-based GPU integration (over 1 GiB) by default
  # so Nix-built GUI apps can render. A server has no display. Everything
  # else, the editor and its full toolchain included, is the same as on a
  # workstation: a server is a dev box too.
  targets.genericLinux.gpu.enable = false;
}
