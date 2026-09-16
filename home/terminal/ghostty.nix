{
  lib,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.hostPlatform.isLinux true;

  # No GNOME launcher is needed: Ghostty's own .desktop file lands in
  # ~/.nix-profile/share/applications, and Home Manager's genericLinux target
  # puts that directory (and ~/.nix-profile/bin) into the GNOME session via
  # ~/.config/environment.d, so the app grid and search find it. Log out and
  # in once after the first switch on a new machine for that to take effect.

  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 16;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration = if pkgs.stdenv.hostPlatform.isDarwin then "zsh" else "bash";
      shell-integration-features = "no-cursor";
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      macos-option-as-alt = "left";
    };
  };
}
