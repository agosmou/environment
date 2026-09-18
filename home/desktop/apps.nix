# Desktop applications: music, chat, notes. Linux workstation only. The Mac
# gets the same apps as Homebrew casks (platform/darwin/Brewfile).
#
# How these get installed: each vendor publishes its own Linux build (a
# .deb, an .rpm, or a tarball). nixpkgs takes that build as-is and wraps it
# with the libraries it needs to run from /nix/store. So what runs is the
# vendor's app, delivered by Nix, which is the same idea as a Homebrew cask
# on the Mac. Some are "unfree" (closed source); flake.nix allows that.
#
# Rendering: like any Nix-built GUI app on Fedora, they find the GPU through
# the integration that is already set up for Ghostty (targets.genericLinux.gpu).
#
# What stays on the machine: each app's settings and your logins. Nothing
# here touches those.
#
# Not in this file, on purpose:
#   ChatGPT/Codex desktop  OpenAI's own rpm, in platform/fedora/packages
#   Mullvad                needs a root daemon, so Mullvad's rpm, same place
#   Claude Desktop         Anthropic ships no Fedora build yet (TODO.md)
{ pkgs, ... }:

{
  home.packages = [
    pkgs.spotify
    pkgs.slack
    pkgs.discord
    pkgs.obsidian
  ];
}
