# ssh client configuration.
#
# Home Manager module: writes ~/.ssh/config. Hosts, usernames, jump hosts, and
# key paths are NOT here: they go in ~/.ssh/config.local, which this file
# includes and which stays on the machine (ssh ignores it if it does not
# exist). Private keys are never repository content.
{ ... }:

{
  programs.ssh = {
    enable = true;
    # Options:
    #   true   Home Manager also writes its own defaults into the "*" block
    #   false  only what is declared here
    enableDefaultConfig = false;
    # Extra files ssh reads, relative to ~/.ssh. A missing file is ignored.
    includes = [ "config.local" ];
    # Settings for every host ("*").
    settings."*" = {
      # Add a key to ssh-agent the first time it is used, so the passphrase
      # is asked once per login, not once per connection.
      # Options:
      #   "yes"      add, keep until the agent exits
      #   "no"       never add
      #   "ask"      ask before adding
      #   "confirm"  add, but confirm each use
      #   "1h"       add, forget after that long
      AddKeysToAgent = "yes";
    };
  };
}
