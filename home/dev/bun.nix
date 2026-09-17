# bun: JavaScript/TypeScript runtime and package manager, in place of Node
# for everyday use (`bun run`, `bun install`, `bunx`). A project that needs
# Node specifically pins it in its own flake. See docs/projects.md.
#
# Plain package.
{ pkgs, ... }:

{
  home.packages = [ pkgs.bun ];
  custom.smoke.bun = "bun --version";
}
