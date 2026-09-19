# gh: the GitHub CLI. Pull requests, issues, checks, and releases from the
# terminal: `gh pr create`, `gh pr checks`, `gh run watch`.
#
# This file installs gh and tells git to ask gh for credentials on HTTPS
# remotes. It does NOT write any of gh's own configuration; see "Why not
# the Home Manager module" below for the failure that rules that out.
#
# What gh keeps under ~/.config/gh, all of it gh's own and none of it
# managed here:
#
#   hosts.yml    the login: which account, its token (or a pointer to the
#                OS keyring), and git_protocol, the protocol gh uses when
#                it clones or adds a remote. Written by `gh auth login`.
#   config.yml   preferences: editor, pager, prompt on/off, aliases.
#                Created by gh with defaults the first time it saves.
#
# Setting up a machine is therefore one interactive command:
#
#   gh auth login
#     Where do you use GitHub?          GitHub.com
#     Preferred protocol?               SSH          <- stored in hosts.yml
#     Generate a new SSH key?           Yes          <- ~/.ssh/id_ed25519, uploaded to the account
#     Title for your SSH key?           <hostname>
#     How to authenticate?              Login with a web browser
#
# After that `git clone git@github.com:...` and every gh command work.
# Optional, once per machine: `gh alias set co 'pr checkout'` for `gh co 123`.
#
# --- Why not the Home Manager module (programs.gh) ------------------------
#
# The first version of this file used `programs.gh = { enable = true;
# settings = { git_protocol = "ssh"; prompt = "enabled"; aliases.co = ... };
# }`. The module renders `settings` to config.yml and links it into the
# read-only Nix store, like every other Home Manager file. That is fatal
# for gh specifically: whenever gh saves anything it rewrites BOTH
# hosts.yml and config.yml, in that order, and it aborts on the first
# error. So on a fresh machine `gh auth login` wrote hosts.yml (the login
# succeeded), then died on config.yml with
#
#   open ~/.config/gh/config.yml: permission denied
#
# and never reached the step after it: uploading the SSH key it had just
# generated. The result was a machine that said "Logged in" while every
# `git clone` failed with "Permission denied (publickey)", fixable only by
# `gh ssh-key add ~/.ssh/id_ed25519.pub` by hand, on every machine, every
# time. `gh alias set` and `gh config set` failed outright for the same
# reason. Upstream considers the rewrite by design and will not change it
# (cli/cli#7360: "commands like `gh auth login` and `gh config set` do
# write to the config file"), and the module has no option to leave
# config.yml alone. Nothing of value was lost by dropping it: prompt =
# "enabled" is gh's default, git_protocol is stored in hosts.yml by the
# login prompt above, and the alias is one command.
#
# Do not bring `programs.gh` back, and do not write config.yml from Nix
# any other way (home.file, xdg.configFile): the same failure follows.
{ pkgs, ... }:

{
  custom.smoke.gh = "gh --version";

  home.packages = [ pkgs.gh ];

  # --- git credential helper ---------------------------------------------
  #
  # A credential helper is a program git runs when a remote asks for a
  # username and password, instead of prompting in the terminal. It is
  # git's mechanism (git-credential(1)), configured in git's config, and
  # has nothing to do with gh's own files above. It matters only for
  # https:// remotes: ssh:// remotes authenticate with the SSH key and never
  # consult it. Since `gh auth login` was answered with SSH, the remotes gh
  # creates are ssh://, and this is a fallback for the HTTPS remotes that
  # appear anyway: a clone URL pasted from the browser (GitHub's "Code"
  # button defaults to HTTPS), a cargo/go/pip git dependency, a submodule
  # someone else added. GitHub rejects account passwords on HTTPS, so
  # without a helper those prompt for a token you would have to create and
  # paste. With it, git runs `gh auth git-credential`, gh answers with the
  # token from hosts.yml, and nothing is asked.
  #
  # This is exactly what programs.gh's gitCredentialHelper option wrote, so
  # the generated ~/.config/git/config is unchanged from the module days.
  # It renders as:
  #
  #   [credential "https://github.com"]
  #       helper =
  #       helper = /nix/store/...-gh/bin/gh auth git-credential
  #
  # Two lines on purpose. git's `helper` setting is a list, and an empty
  # entry is git's idiom for "discard any helpers configured at a lower
  # level" (a system-wide /etc/gitconfig, say, pointing at a keyring gh
  # knows nothing about), so that only gh answers for GitHub.
  #
  # It lives under programs.git because it is git configuration; Nix merges
  # it with home/git/git.nix. Kept here so gh and its helper travel
  # together: remove this file and git stops asking gh for anything.
  programs.git.settings.credential = {
    "https://github.com".helper = [
      ""
      "${pkgs.gh}/bin/gh auth git-credential"
    ];
    "https://gist.github.com".helper = [
      ""
      "${pkgs.gh}/bin/gh auth git-credential"
    ];
  };
}
