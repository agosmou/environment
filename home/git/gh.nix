# gh: the GitHub CLI. Pull requests, issues, checks, and releases from the
# terminal: `gh pr create`, `gh pr checks`, `gh run watch`.
#
# Home Manager module: installs gh and writes ~/.config/gh/config.yml from
# `settings`. Login state (~/.config/gh/hosts.yml) is not managed; run
# `gh auth login` once per machine.
{ ... }:

{
  custom.smoke.gh = "gh --version";

  programs.gh = {
    enable = true;
    # Let git use gh's login for GitHub over HTTPS, so no separate token is
    # needed. Harmless with git_protocol = "ssh" below; it only applies to
    # HTTPS remotes.
    # Options:
    #   true   register gh as git's credential helper for github.com
    #   false  git asks for credentials itself
    gitCredentialHelper.enable = true;
    settings = {
      # Protocol gh uses when it clones or adds a remote.
      # Options:
      #   "ssh"    git@github.com:owner/repo, authenticated by your SSH key
      #   "https"  https://github.com/owner/repo, authenticated by gh's token
      git_protocol = "ssh";
      # Options:
      #   "enabled"   gh asks interactively when a command needs input
      #   "disabled"  gh fails instead; for scripts
      prompt = "enabled";
      # `gh co 123` checks out pull request 123.
      aliases.co = "pr checkout";
    };
  };
}
