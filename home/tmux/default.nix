{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.tmux;

  # nixpkgs ships a 2024 snapshot of tmux-power without the section options
  # (@tmux_power_left_a, @tmux_power_right_w..z) the status layout uses.
  tmuxPower = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "power";
    rtpFilePath = "tmux-power.tmux";
    version = "unstable-2026-09-15";
    src = pkgs.fetchFromGitHub {
      owner = "wfxr";
      repo = "tmux-power";
      rev = "d69c4d7ffc64828ac5ac4b3056dacdd7ef51997f";
      hash = "sha256-NRJcny3hCyqjp8SuzyC3Zc33rJqpUzs6rbWFgO8yb7c=";
    };
  };

  keepBest = pkgs.writeShellApplication {
    name = "resurrect-keep-best";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.tmux
    ];
    text = builtins.readFile ./resurrect-keep-best.sh;
  };

  resurrectDir = "${config.xdg.dataHome}/tmux/resurrect";

  # Right side runs inner (w) to outer (z). Wide clients get CPU/RAM and the
  # full date; narrow clients keep the bar short.
  wide = "#{>:#{client_width},180}";
  rightW = "#{?${wide}, 󰍛 #{cpu_percentage} 󰾆 #{ram_percentage},}";
  rightX = lib.optionalString cfg.laptopWidgets " #{battery_icon} #{battery_percentage} #{online_status}";
  rightY = "#{?${wide}, %a %H:%M  ·  %F, %H:%M}";
  rightZ = " #{USER}@#h";
in
{
  options.custom.tmux.laptopWidgets = lib.mkEnableOption "battery and online-status segments";

  config = {
    home.packages = [ pkgs.sesh ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.procps ];
    custom.smoke = {
      tmux = "tmux -V";
      sesh = "sesh --version";
    };

    programs.tmux = {
      enable = true;
      prefix = "C-Space";
      mouse = true;
      historyLimit = 100000;
      baseIndex = 1;
      keyMode = "vi";
      terminal = "tmux-256color";
      escapeTime = 10;
      focusEvents = true;
      secureSocket = true;

      # Order matters: the theme builds status-right, the widget plugins then
      # replace their tokens inside it, and continuum prepends its save hook
      # last so a theme reload cannot drop the autosave.
      plugins = [
        {
          plugin = pkgs.tmuxPlugins.resurrect;
          extraConfig = ''
            set -g @resurrect-dir '${resurrectDir}'
            set -g @resurrect-hook-post-save-all '${keepBest}/bin/resurrect-keep-best'
          '';
        }
        {
          plugin = tmuxPower;
          extraConfig = ''
            set -g @tmux_power_theme 'everforest'
            set -g @tmux_power_status_interval 5
            set -g @tmux_power_right_arrow_icon '''
            set -g @tmux_power_left_arrow_icon '''
            set -g @tmux_power_left_a ' #S'
            set -g @tmux_power_left_b '''
            set -g @tmux_power_right_w '${rightW}'
            set -g @tmux_power_right_x '${rightX}'
            set -g @tmux_power_right_y '${rightY}'
            set -g @tmux_power_right_z '${rightZ}'
          '';
        }
        pkgs.tmuxPlugins.cpu
      ]
      ++ lib.optionals cfg.laptopWidgets [
        {
          plugin = pkgs.tmuxPlugins.battery;
          extraConfig = ''
            set -g @batt_icon_status_charged '󰂄'
            set -g @batt_icon_status_charging '󰂄'
            set -g @batt_icon_status_discharging '󰁾'
            # Plugged in but held below the charge limit (platform/fedora/
            # battery.conf): macOS reports "AC attached; not charging", upower
            # reports "pending-charge", which the plugin only knows as unknown.
            set -g @batt_icon_status_attached '󰚥'
            set -g @batt_icon_status_unknown '󰚥'
          '';
        }
        {
          plugin = pkgs.tmuxPlugins.online-status;
          extraConfig = ''
            set -g @online_icon '#[fg=#a7c080]󰖟#[default]'
            set -g @offline_icon '#[fg=#e67e80]󰞐#[default]'
          '';
        }
      ]
      ++ [
        {
          plugin = pkgs.tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
          '';
        }
      ];

      extraConfig = ''
        # tmux 3.7 draws the command prompt on top of the status line and only
        # clears it when the style has a fill; tmux-power sets the style
        # without one, so the window tabs showed through the rename prompt.
        # Colours are the theme's everforest text and G0 background.
        set -g message-style 'fg=#a7c080,bg=#262626,fill=#262626'
        set -g message-command-style 'fg=#a7c080,bg=#262626,fill=#262626'

        set -g pane-base-index 1
        set -g renumber-windows on
        set -g set-clipboard on
        set -s extended-keys on
        set -as terminal-features 'xterm*:RGB'
        set -as terminal-features 'xterm*:extkeys'
        set -g allow-passthrough on
        set -ag update-environment ' WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY SSH_AUTH_SOCK'

        unbind C-b
        bind C-Space send-prefix
        bind r source-file ~/.config/tmux/tmux.conf \; display-message 'tmux reloaded'

        bind c new-window -c '#{pane_current_path}'
        bind | split-window -h -c '#{pane_current_path}'
        bind - split-window -v -c '#{pane_current_path}'
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # sesh: sessions, then zoxide directories, in an fzf popup.
        bind-key s run-shell "sesh connect \"$(
          sesh list --icons | fzf --tmux center,80%,70% \
            --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
            --header '^a all  ^t tmux  ^x zoxide' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)'
        )\""

        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
        bind -n C-h if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
        bind -n C-j if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
        bind -n C-k if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
        bind -n C-l if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        # Dragging copies and stays where you are; on the live screen (not
        # scrolled up) it drops back to the prompt so keys go to the shell.
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-no-clear \; if-shell -F '#{==:#{scroll_position},0}' 'send-keys -X cancel'
        bind-key -T copy-mode-vi DoubleClick1Pane send-keys -X select-word \; send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi TripleClick1Pane send-keys -X select-line \; send-keys -X copy-selection-and-cancel
        bind-key -T root DoubleClick1Pane select-pane -t = \; if-shell -F '#{||:#{pane_in_mode},#{mouse_any_flag}}' 'send-keys -M' 'copy-mode -H ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-selection-and-cancel'
        bind-key -T root TripleClick1Pane select-pane -t = \; if-shell -F '#{||:#{pane_in_mode},#{mouse_any_flag}}' 'send-keys -M' 'copy-mode -H ; send-keys -X select-line ; run-shell -d 0.3 ; send-keys -X copy-selection-and-cancel'
        # A press starts a possible drag, so it must not leave copy mode; a
        # release with no drag (MouseUp, never sent after a drag) is the
        # single click that jumps back to the prompt.
        bind-key -T copy-mode-vi MouseDown1Pane select-pane \; send-keys -X clear-selection
        bind-key -T copy-mode-vi MouseUp1Pane send-keys -X cancel
        bind-key -T copy-mode-vi WheelDownPane send-keys -X -N 3 scroll-down \; if-shell -F '#{==:#{scroll_position},0}' 'send-keys -X cancel'
        set-hook -g after-select-window 'if-shell -F "#{pane_in_mode}" "send-keys -X cancel"'
      '';
    };
  };
}
