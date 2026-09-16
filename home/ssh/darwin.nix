# macOS only: store SSH key passphrases in the Keychain, so they survive a
# reboot and are not asked again. Linux has no equivalent setting; the agent
# handles it there.
{ ... }:

{
  # Options:
  #   "yes"  passphrases are read from and saved to the macOS Keychain
  #   "no"   ask each time the agent starts
  programs.ssh.settings."*".UseKeychain = "yes";
}
