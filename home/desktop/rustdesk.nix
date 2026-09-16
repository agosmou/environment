# RustDesk: remote desktop, for reaching the Mac from Linux and vice versa
# over Tailscale. Linux workstation only; the Mac installs it through
# Homebrew because nixpkgs marks it unsupported on Apple Silicon.
#
# Plain package: nothing to configure. Its own settings and the unattended
# access password are set in the app and stay on the machine.
# Setup and connecting: docs/remote-access.md.
{ pkgs, ... }:

{
  home.packages = [ pkgs.rustdesk ];
  custom.smoke.rustdesk = "rustdesk --version";
}
