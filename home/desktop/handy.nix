# Handy: offline speech-to-text. Press Super+D, speak, press Super+D again,
# and the text is typed into the focused window. Nothing leaves the machine:
# the model (picked in Handy's first-run screen) runs locally on the GPU.
# Linux workstation only.
#
# Needs one root step this module cannot do: a udev rule giving the
# logged-in user access to /dev/uinput, so dotool can create a virtual
# keyboard. platform/fedora/bootstrap.sh installs it from
# platform/fedora/uinput.rules.
#
# Do not add wtype: Handy prefers it when present, and it fails silently
# on GNOME (mutter lacks the virtual-keyboard protocol wtype needs).
#
# Handy keeps a WAV of every recording in
# ~/.local/share/com.pais.handy/recordings/ and the text in history.db.
{ pkgs, lib, ... }:

{
  home.packages = [
    pkgs.handy
    # Types Handy's text through /dev/uinput; works under GNOME Wayland.
    pkgs.dotool
  ];
  custom.smoke.dotool = "dotool --version";

  # On Wayland, apps cannot grab global shortcuts, so GNOME owns the key
  # and runs Handy's toggle; the first press also starts Handy if it is
  # not running. The list below replaces ALL custom shortcuts: add any
  # others here too, or they are dropped at the next apply.
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/handy/"
    ];
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/handy" = {
      name = "Toggle Handy Transcription";
      command = "${lib.getExe pkgs.handy} --toggle-transcription";
      # Options: any GNOME accelerator string, for example
      #   "<Super>d"         Super+D ("dictate"); free in stock GNOME
      #   "<Control><Alt>d"  Ctrl+Alt+D
      # Not "<Super>o" (GNOME's rotation lock) or "<Control>space" (the
      # tmux prefix, see home/tmux).
      binding = "<Super>d";
    };
  };
}
