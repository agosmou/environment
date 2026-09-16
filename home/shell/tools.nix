# Plain command-line binaries with no configuration. Installed and nothing
# else; see the header of any programs.* file in this directory for the
# difference.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.curl
    pkgs.eza # ls replacement; the ll and la aliases use it
    pkgs.fd # find replacement; also used by Neovim's file picker
    pkgs.jaq # faster jq clone; jq kept for scripts that assume it
    pkgs.jq
    pkgs.lazygit # terminal git UI; the lg alias
    pkgs.ripgrep # grep replacement; also used by Neovim's live grep
    pkgs.yazi # terminal file manager; the y function
  ];

  custom.smoke = {
    curl = "curl --version";
    eza = "eza --version";
    fd = "fd --version";
    jaq = "jaq --version";
    jq = "jq --version";
    lazygit = "lazygit --version";
    rg = "rg --version";
    yazi = "yazi --version";
  };
}
