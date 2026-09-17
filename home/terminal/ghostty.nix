{
  lib,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  # On macOS the binary comes from Homebrew, outside Home Manager, so there
  # is nothing in the generation to smoke-test there.
  custom.smoke = lib.mkIf pkgs.stdenv.hostPlatform.isLinux { ghostty = "ghostty --version"; };
  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.hostPlatform.isLinux true;

  # No GNOME launcher is needed: Ghostty's own .desktop file lands in
  # ~/.nix-profile/share/applications, and Home Manager's genericLinux target
  # puts that directory (and ~/.nix-profile/bin) into the GNOME session via
  # ~/.config/environment.d, so the app grid and search find it. Log out and
  # in once after the first apply on a new machine for that to take effect.

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 16;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration = if pkgs.stdenv.hostPlatform.isDarwin then "zsh" else "bash";
      # Ghostty announces itself as TERM=xterm-ghostty, which remote hosts do
      # not know; without the ssh-* features, tmux over ssh fails with
      # "missing or unsuitable terminal".
      # Values (prefix "no-" to turn one off):
      #   cursor        shell integration changes the cursor shape; off, tmux and Neovim manage it
      #   ssh-env       ssh sends a TERM the remote understands (xterm-256color) plus COLORTERM
      #   ssh-terminfo  ssh first copies Ghostty's terminfo to the remote so xterm-ghostty works there
      #   sudo          keep shell integration under sudo
      #   title         set the window title from the shell
      #   path          add Ghostty's bin dir to PATH
      shell-integration-features = "no-cursor,ssh-env,ssh-terminfo";
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      macos-option-as-alt = "left";
    };
  };
}
