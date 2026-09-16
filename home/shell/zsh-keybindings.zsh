# Key bindings for zsh's line editor (ZLE): the command line you are typing
# at the prompt, before you press Enter. Same idea as the readline bindings
# in bash.nix, in zsh's own `bindkey` syntax.
#
# zsh is in emacs mode (defaultKeymap = "emacs" in zsh.nix), so Ctrl-A,
# Ctrl-E, Ctrl-K and friends already work. What emacs mode does not know are
# the byte sequences Ghostty and tmux send for some keys. When you press
# Ctrl+Left the terminal sends ESC [ 1 ; 5 D (^[ is ESC below); without a
# binding zsh types `;5D` instead of jumping a word, and Home/End/Delete do
# nothing. `-M emacs` means "in the emacs keymap."
bindkey -M emacs '^[[1;5D' backward-word   # Ctrl+Left
bindkey -M emacs '^[[1;5C' forward-word    # Ctrl+Right
bindkey -M emacs '^[[1;3D' backward-word   # Alt+Left
bindkey -M emacs '^[[1;3C' forward-word    # Alt+Right
bindkey -M emacs '^[[H' beginning-of-line  # Home
bindkey -M emacs '^[[F' end-of-line        # End
bindkey -M emacs '^[[1~' beginning-of-line # Home, alternate code
bindkey -M emacs '^[[4~' end-of-line       # End, alternate code
bindkey -M emacs '^[[3~' delete-char       # Delete
