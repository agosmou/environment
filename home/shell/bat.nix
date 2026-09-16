# bat: `cat` with syntax highlighting and line numbers. Use it as `bat file`;
# `cat` itself is untouched.
#
# Home Manager module: installs the binary and writes ~/.config/bat/config.
{ ... }:

{
  programs.bat.enable = true;
  custom.smoke.bat = "bat --version";
}
