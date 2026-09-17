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

  # Where the binary comes from. macOS: the Homebrew cask, a repackaging of
  # the official .dmg (platform/darwin/Brewfile). Fedora: nixpkgs, and this
  # is the one exception to "GUI apps come from the OS's own channel".
  #
  # Why not the Fedora way (dnf copr enable scottames/ghostty)? Ghostty's
  # install page sorts Linux builds into tiers. Fedora has no package of its
  # own, so it is not in the "built, tested and verified by the distributions
  # themselves" tier where Arch, Ubuntu, and Nix sit; the COPR is listed
  # under "Community Binaries", with the warning that they "carry a much
  # higher risk" and are "compiled beforehand on a computer that might not
  # be held to the same security standards". nixpkgs' build is in the
  # distro-maintained tier, built from source by nixpkgs' CI, and pinned
  # here by flake.lock. The cost is real: about 900 MiB of its own GTK stack
  # plus the GPU integration (targets.genericLinux.gpu), which is the setup
  # the same page describes under "Nix on other distros" for Home Manager.
  #   https://ghostty.org/docs/install/binary#fedora
  #   https://ghostty.org/docs/install/binary#nix-on-other-distros
  # (docs/nix.md, "GUI Apps")
  programs.ghostty = {
    enable = true;
    # Options:
    #   null           Home Manager writes the config only; the binary comes from elsewhere
    #   pkgs.ghostty   Home Manager installs the nixpkgs build too
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
