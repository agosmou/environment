# bash, the shell on every Linux target. Home Manager writes ~/.bashrc and
# ~/.inputrc from this file.
{ ... }:

{
  # Add ~/.local/bin and ~/bin to PATH, for scripts you drop there yourself
  # outside Nix.
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
  ];

  programs.bash = {
    enable = true;
    # Don't record duplicate commands, and don't record a command you prefix
    # with a space (handy for one-offs with tokens in them).
    # Options:
    #   "ignoredups"   skip a command identical to the previous one
    #   "ignorespace"  skip commands starting with a space
    #   "ignoreboth"   both of the above
    #   "erasedups"    also delete older copies when a command is run again
    historyControl = [ "ignoreboth" ];
    # The aliases file becomes `alias gst='git status'` lines in ~/.bashrc.
    shellAliases = import ./aliases.nix;
    # Before anything else, load the system's bashrc. Fedora keeps it at
    # /etc/bashrc, Debian at /etc/bash.bashrc; this tries both. Without it
    # you lose distro defaults like the command-not-found hint.
    bashrcExtra = ''
      if [[ -f /etc/bash.bashrc ]]; then
        source /etc/bash.bashrc
      elif [[ -f /etc/bashrc ]]; then
        source /etc/bashrc
      fi
    '';
    # At the end, source functions.sh. `${./functions.sh}` means Nix copies
    # the file into the store and puts that path here, so ~/.bashrc sources
    # an immutable copy.
    initExtra = ''
      source ${./functions.sh}
    '';
  };

  # Everything in this block is about the command line you are typing at the
  # prompt, before you press Enter: how the cursor moves, what Esc does. It
  # affects nothing else (not command output, not Neovim, not tmux). readline
  # is the library bash uses for that line; this writes ~/.inputrc.
  programs.readline = {
    enable = true;
    variables = {
      # emacs mode: no modes to be in, Ctrl-A/Ctrl-E/arrows just work, and
      # you never end up in vi normal mode on the command line by accident.
      # Stated explicitly (it is the default) so the choice is visible and
      # matches zsh on macOS.
      # Options:
      #   "emacs"  Ctrl-A start of line, Ctrl-E end, Ctrl-K delete to end; no modes
      #   "vi"     Esc enters normal mode with hjkl, dw, ciw, and so on
      editing-mode = "emacs";
    };
    # When you press Ctrl+Left, the terminal does not send "Ctrl+Left"; it
    # sends the byte sequence ESC [ 1 ; 5 D. readline knows the common
    # sequences but not all of the ones Ghostty and tmux emit. Each line
    # says "when you see this sequence, do this action." Without them,
    # Ctrl+Left types `;5D` into your command line instead of jumping a
    # word, and Home/End/Delete do nothing.
    bindings = {
      "\\e[1;5D" = "backward-word"; # Ctrl+Left
      "\\e[1;5C" = "forward-word"; # Ctrl+Right
      "\\e[1;3D" = "backward-word"; # Alt+Left
      "\\e[1;3C" = "forward-word"; # Alt+Right
      "\\e[H" = "beginning-of-line"; # Home
      "\\e[F" = "end-of-line"; # End
      "\\e[1~" = "beginning-of-line"; # Home, alternate code
      "\\e[4~" = "end-of-line"; # End, alternate code
      "\\e[3~" = "delete-char"; # Delete
    };
  };
}
