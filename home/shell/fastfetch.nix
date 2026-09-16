# fastfetch: one-screen summary of the machine (OS, kernel, CPU, GPU, memory,
# uptime, shell, terminal). Run `fastfetch` by hand on any target.
#
# Home Manager module: installs the binary and writes
# ~/.config/fastfetch/config.jsonc.
#
# On workstations it also prints once per terminal window, as a quick "which
# machine am I on". Servers get the package only: an SSH login is for doing
# something, not for a banner. The target file turns the greeting on:
#
#   custom.fastfetch.greeting = true;
{ config, lib, ... }:

let
  cfg = config.custom.fastfetch;
  # Skip inside tmux, otherwise every new pane would print it. $TMUX is set
  # only for shells running under tmux.
  greeting = ''
    [[ -z "$TMUX" ]] && fastfetch
  '';
in
{
  # This module invents a setting of its own so target files can turn the
  # greeting on. A Nix module that declares a setting splits into two halves:
  #   options  declare "a setting called X exists" (type, default, description)
  #   config   set things, possibly depending on X
  # Every other module only sets existing Home Manager settings, so it has
  # no `options` half and no `config` wrapper. Same shape as home/tmux.

  # mkEnableOption = a true/false setting, default false.
  # Values:
  #   true   print the summary when a terminal window opens
  #   false  installed, run by hand only (the default)
  options.custom.fastfetch.greeting = lib.mkEnableOption "fastfetch when a terminal opens";

  config = {
    programs.fastfetch.enable = true;

    # mkIf: only add these lines to the shell configs when the setting is on.
    programs.bash.initExtra = lib.mkIf cfg.greeting greeting;
    programs.zsh.initContent = lib.mkIf cfg.greeting greeting;
  };
}
