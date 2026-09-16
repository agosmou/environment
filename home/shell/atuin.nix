# atuin: shell history with fuzzy search on Ctrl-R, stored in a local SQLite
# database instead of a flat text file. Every shell on the machine shares it.
# Never synced to atuin's cloud service.
#
# Home Manager module: installs the binary, writes ~/.config/atuin/config.toml
# from `settings`, adds the Ctrl-R hook to ~/.bashrc and ~/.zshrc, and runs the
# daemon as a user service.
{ ... }:

{
  custom.smoke.atuin = "atuin --version";

  programs.atuin = {
    enable = true;
    # Which keys atuin takes over.
    # Options:
    #   "--disable-up-arrow"  up arrow keeps normal shell history; Ctrl-R opens atuin
    #   "--disable-ctrl-r"    the reverse
    #   "--disable-ai"        no AI command suggestions
    flags = [ "--disable-up-arrow" ];
    settings = {
      # Options:
      #   true   upload history to atuin's sync server after each command
      #   false  history stays on this machine
      auto_sync = false;
      # How typed text matches history.
      # Options:
      #   "fuzzy"         characters in order, gaps allowed, like fzf
      #   "prefix"        history entry starts with the typed text
      #   "fulltext"      history entry contains the typed text
      #   "daemon-fuzzy"  fuzzy, ranked by the daemon
      search_mode = "fuzzy";
      # Options:
      #   "compact"  a plain list
      #   "full"     list plus a header with filter mode and stats
      #   "auto"     full when the terminal is tall, compact otherwise
      style = "compact";
      # Rows the search list takes up. 0 means full screen.
      inline_height = 20;
      # Options:
      #   true   show the full command under the list when it is cut off
      #   false  no preview
      show_preview = true;
      # Options:
      #   true   Enter runs the selected command; Tab pastes it to edit
      #   false  both keys paste it to the prompt to edit
      enter_accept = true;
      # Options:
      #   true   store history in the newer record format (the daemon needs it)
      #   false  legacy format
      sync.records = true;
    };
    # Options:
    #   true   a background process writes history, so the shell never blocks on it
    #   false  each shell writes its own history
    daemon.enable = true;
  };
}
