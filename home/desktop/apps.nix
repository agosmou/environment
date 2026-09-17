# Desktop applications that are not part of the work environment: music and
# chat. Linux workstation only; the Mac gets the same three as Homebrew casks
# (platform/darwin/Brewfile).
#
# All three are the vendors' own binaries, repackaged by nixpkgs with the
# libraries they need (Spotify's deb, Slack's rpm, Discord's tarball), which
# is the same thing the casks do on the Mac. They are unfree; flake.nix
# allows that. They render through the GPU integration already in place for
# Ghostty (targets.genericLinux.gpu). Their settings and logins stay on the
# machine.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.spotify
    pkgs.slack
    pkgs.discord
  ];
}
