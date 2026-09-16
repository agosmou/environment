{
  lib,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.hostPlatform.isLinux true;

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
