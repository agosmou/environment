# Typst: a typesetting system for writing documents (letters, papers, slides,
# one-page PDFs) from a plain-text source, like LaTeX with a smaller language
# and a compiler that finishes in milliseconds. `typst compile doc.typ` writes
# doc.pdf; `typst watch doc.typ` rewrites it on every save. Workstations only:
# it is for writing at a desk, not for a server.
#
# Why nixpkgs and not github:typst/typst-flake: nixpkgs on the pinned lock
# ships the current Typst release, and the flake's only advantage is building
# unreleased commits. One fewer input to keep in sync.
#
# tinymist is the Typst language server: completion, hover, diagnostics, and
# formatting (it bundles typstyle, so no separate formatter binary). It is on
# the shell PATH rather than Neovim's private one because it is a command-line
# tool as well (`tinymist compile`, `tinymist preview`).
{ pkgs, ... }:

{
  home.packages = [
    pkgs.typst
    pkgs.tinymist
  ];
  custom.smoke = {
    typst = "typst --version";
    tinymist = "tinymist --version";
  };
  # Neovim's config starts tinymist for .typ files (init.lua, LSP section),
  # and snacks.image shells out to typst to render math in Markdown. Both
  # are inherited from the shell PATH, same arrangement as gopls in go.nix;
  # registering them here lets doctor check them from inside Neovim.
  custom.neovimTools = [
    "typst"
    "tinymist"
  ];
}
