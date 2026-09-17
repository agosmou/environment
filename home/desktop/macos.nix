# macOS settings, the counterpart of gnome.nix: the same preferences,
# written through `defaults` (macOS's settings database). Mac workstation
# only.
#
# Home Manager module: writes these keys on every apply. A value changed in
# System Settings by hand is reverted next apply; change it here instead.
# Some take effect at next login.
{ ... }:

{
  targets.darwin.defaults = {
    # Scrolling direction for trackpad and mouse. NSGlobalDomain is the
    # setting every app reads.
    # Options:
    #   true   natural: content follows the fingers, as on iOS (the macOS default)
    #   false  traditional: the scrollbar follows the fingers
    "NSGlobalDomain"."com.apple.swipescrolldirection" = true;

    # Tap the trackpad to click, without pressing. Two keys because macOS
    # keeps one for the built-in trackpad and one for a Bluetooth one.
    # Options:
    #   true   tap to click
    #   false  press to click
    "com.apple.AppleMultitouchTrackpad".Clicking = true;
    "com.apple.driver.AppleBluetoothMultitouch.trackpad".Clicking = true;

    # Key repeat, to match gnome.nix. macOS counts in units of 15 ms.
    # Options: whole numbers; the Settings sliders cover 15-120 for the
    # initial delay and 2-120 for the interval.
    #   InitialKeyRepeat 25  about 375 ms before repeating (35 is the default, about 525 ms)
    #   KeyRepeat 2          about 30 ms between repeats, the fastest the slider allows
    "NSGlobalDomain".InitialKeyRepeat = 25;
    "NSGlobalDomain".KeyRepeat = 2;
  };
}
