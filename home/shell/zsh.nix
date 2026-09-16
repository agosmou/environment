# zsh, the default shell on macOS. Only the Darwin target imports this.
{ config, lib, ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
  ];

  programs.zsh = {
    enable = true;
    # emacs mode, matching bash on Linux: no modes, Ctrl-A/E/arrows just
    # work on the command line.
    # Options:
    #   "emacs"  Ctrl-A start of line, Ctrl-E end, Ctrl-K delete to end; no modes
    #   "viins"  vi, each new line starts in insert mode
    #   "vicmd"  vi, each new line starts in normal mode
    defaultKeymap = "emacs";
    # Shared aliases plus macOS-only ones: Finder and the system clipboard.
    shellAliases = (import ./aliases.nix) // {
      open-here = "open .";
      copy = "pbcopy";
      paste = "pbpaste";
    };
    history = {
      path = "${config.xdg.dataHome}/zsh/history"; # ~/.local/share, not ~/.zsh_history
      size = 10000;
      save = 10000;
      share = true; # every open terminal sees every other terminal's commands
      ignoreDups = true;
      ignoreSpace = true; # a leading space keeps a command out of history
    };
    # Any zsh option name from `man zshoptions`. This one allows # comments
    # on the command line, so a pasted snippet with comments still runs.
    setOptions = [ "INTERACTIVE_COMMENTS" ];
    autosuggestion.enable = true; # grey inline suggestion from history; Right arrow accepts
    syntaxHighlighting.enable = true; # valid commands green, invalid red, as you type
    # mkOrder 1300 runs this after Home Manager's own zsh setup, so these
    # bindings are not overwritten by the plugins above.
    initContent = lib.mkOrder 1300 ''
      source ${./functions.sh}
      source ${./zsh-keybindings.zsh}
    '';
  };
}
