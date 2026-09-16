# Settings every target shares.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Which target this configuration is, e.g. "workstation-x86_64-linux". Each
  # file under targets/ sets it. Home Manager writes it to
  # ~/.config/environment/target so that after the first bootstrap the just
  # recipes know which machine this is and no longer need to be told.
  options.custom.target = lib.mkOption {
    type = lib.types.str;
    description = "the target name this machine runs";
  };

  # Every module that installs a command registers how to prove it runs:
  #   custom.smoke.nvim = "nvim --version";
  # The flake's smoke check runs every entry from the built generation on
  # each CPU/OS, and `doctor` checks every name is on PATH. So a tool is
  # tested by the one line in its own file, and there is no list elsewhere
  # to keep in sync.
  options.custom.smoke = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "command name to an invocation that exits 0 if the tool runs";
  };

  config = {
    xdg.configFile."environment/target".text = config.custom.target + "\n";

    # The Home Manager release this configuration started on. It pins
    # nothing: packages and Home Manager itself still update normally. It is
    # a compatibility marker. When a newer release changes a default (for
    # example, where a program keeps its data), Home Manager uses this to
    # keep the old behaviour for an existing setup instead of silently
    # migrating. Leave it alone unless the release notes for a newer version
    # describe a change you want; then raise it to that version.
    home.stateVersion = "26.05";

    home.packages = [
      pkgs.just # the command runner for this repository's justfile
    ];
    custom.smoke.just = "just --version";

    xdg.enable = true;
    programs.home-manager.enable = true;
  };
}
