{ pkgs, ... }:

{
  programs.neovim.extraPackages = [
    pkgs.ghostscript
    pkgs.imagemagick
    pkgs.poppler-utils
  ];
}
