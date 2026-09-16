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

    xdg.enable = true;
    programs.home-manager.enable = true;
  };
}
