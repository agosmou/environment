# Xcode project tooling. Mac workstation only: Xcode itself comes from the
# App Store and is not managed here.
#
# Home Manager module: installs xcodegen, which generates an .xcodeproj from
# a project.yml so the generated project need not be committed.
{ pkgs, ... }:

{
  home.packages = [ pkgs.xcodegen ];
  custom.smoke.xcodegen = "xcodegen --version";
}
