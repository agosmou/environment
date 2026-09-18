# JavaScript/TypeScript, global: bun as the runtime and package manager for
# everyday use, pnpm for repositories that use a pnpm lockfile. A project that
# needs Node specifically pins it in its own flake. See docs/projects.md.
#
# Editor tooling for JS/TS (language servers, formatters) lives in
# home/neovim/default.nix, since it is Neovim that runs it.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.bun
    pkgs.pnpm
  ];
  custom.smoke = {
    bun = "bun --version";
    pnpm = "pnpm --version";
  };
}
