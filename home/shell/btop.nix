# btop: `top` replacement with CPU, memory, disk, network, and process views.
#
# Home Manager module: installs the binary and writes ~/.config/btop/btop.conf.
{ ... }:

{
  programs.btop.enable = true;
  custom.smoke.btop = "btop --version";
}
