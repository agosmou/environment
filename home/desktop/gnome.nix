# GNOME settings for the Fedora workstation, written through dconf (GNOME's
# settings database; the same values `gsettings` or Settings would set).
# Linux workstation only.
#
# Home Manager module: writes these keys at every apply, so a value changed
# in Settings by hand is reverted next apply. Add it here instead.
{ lib, ... }:

{
  dconf.settings = {
    # XKB options are keyboard tweaks GNOME can apply itself. Empty so it
    # applies none: key remapping is keyd's job at the system level, and
    # both fighting over Caps Lock gives inconsistent results.
    # Options: a list of strings from `xkeyboard-config(7)`, for example
    #   "caps:escape"       Caps Lock acts as Esc
    #   "caps:swapescape"   swap Caps Lock and Esc
    #   "ctrl:nocaps"       Caps Lock acts as Ctrl
    #   "compose:ralt"      Right Alt is the Compose key
    "org/gnome/desktop/input-sources".xkb-options = [ ];

    # Key repeat: hold a key and it repeats. Stated so every machine feels
    # the same. mkUint32 because dconf stores these as unsigned 32-bit ints
    # and Nix would otherwise send a signed int, which dconf rejects.
    "org/gnome/desktop/peripherals/keyboard" = {
      # Options:
      #   true   holding a key repeats it
      #   false  one keypress, one character
      repeat = true;
      # Milliseconds a key is held before it starts repeating.
      # Options: any whole number; GNOME's Settings slider covers 100-2000.
      #   500   the GNOME default
      #   250   noticeably snappier; Neovim's hjkl start moving sooner
      delay = lib.hm.gvariant.mkUint32 500;
      # Milliseconds between repeats once started. Lower is faster.
      # Options: any whole number; GNOME's Settings slider covers 10-110.
      #   30    the GNOME default, about 33 repeats per second
      #   20    fast; 50 per second
      repeat-interval = lib.hm.gvariant.mkUint32 30;
    };

    # Touchpad. Every key GNOME's Settings > Mouse & Touchpad exposes.
    "org/gnome/desktop/peripherals/touchpad" = {
      # Options:
      #   true   natural: content follows the fingers, as on a phone
      #   false  traditional: the scrollbar follows the fingers
      natural-scroll = true;
      # Options:
      #   true   tap to click
      #   false  press to click
      tap-to-click = true;
      # Options:
      #   true   scroll with two fingers anywhere on the pad
      #   false  scroll only on the right edge (see edge-scrolling-enabled)
      two-finger-scrolling-enabled = true;
      # How a right-click is made.
      # Options:
      #   "fingers"  two-finger tap or click (the GNOME default)
      #   "areas"    click in the bottom-right corner of the pad
      #   "none"     no right-click from the touchpad
      #   "default"  whatever the hardware driver prefers
      click-method = "fingers";
    };

    # Mouse: a wheel scrolls the traditional way even though the touchpad
    # is natural, since a wheel is not a surface.
    # Options: true, false (same meanings as for the touchpad)
    "org/gnome/desktop/peripherals/mouse".natural-scroll = false;

    # No custom shortcut for the Activities overview (app search): tapping
    # Super alone already opens it, GNOME's default. That is the Spotlight
    # equivalent; Cmd+Space on the Mac, Super on Fedora.
  };
}
