# git, with delta as the diff viewer.
#
# Home Manager module: installs git and writes ~/.config/git/config and
# ~/.config/git/ignore from this file.
#
# Your name and email are NOT here, so this repository can be public. They
# come from a gitignored file you create once per machine:
#
#   # ~/environment/local/gitconfig.local
#   [user]
#       name = Your Name
#       email = you@example.com
{ ... }:

{
  custom.smoke = {
    git = "git --version";
    git-lfs = "git-lfs --version";
    delta = "delta --version";
  };

  programs.git = {
    enable = true;
    # Git Large File Storage, for repositories that store big binaries.
    # Options:
    #   true   install git-lfs and register its filters in the git config
    #   false  plain git; cloning an LFS repo leaves pointer files
    lfs.enable = true;
    # Global ignore list, applied to every repository on this machine. Only
    # files that tools drop into repos and that are about this machine, never
    # project files (those belong in the project's own .gitignore).
    ignores = [
      ".DS_Store" # macOS Finder writes one into every directory it opens
      "**/.claude/settings.local.json" # Claude Code: permissions you approved on this machine
    ];
    # Files git reads in addition to this config. Identity lives here so it
    # never enters the repository.
    includes = [
      { path = "~/environment/local/gitconfig.local"; }
    ];
    settings = {
      # Editor for commit messages and interactive rebase.
      core.editor = "nvim";
      # Program that displays diffs and logs. delta is configured below.
      core.pager = "delta";
      # Same for `git add -p` hunks, which use a separate setting.
      interactive.diffFilter = "delta --color-only";
      # How a conflict is shown in the file.
      # Options:
      #   "merge"   ours and theirs only
      #   "diff3"   ours, the common ancestor, and theirs; shows what both sides changed
      #   "zdiff3"  diff3 with identical leading and trailing lines trimmed
      merge.conflictStyle = "diff3";
      # Branch name `git init` creates.
      init.defaultBranch = "main";
      # What `git pull` does with local commits when the remote moved.
      # Options:
      #   true           rebase local commits on top of the remote
      #   false          create a merge commit
      #   "merges"       rebase, but keep local merge commits
      #   "interactive"  rebase interactively
      pull.rebase = true;
    };
  };

  # delta: syntax-highlighted, side-by-side diffs for git.
  #
  # Home Manager module: installs delta and writes its section into the git
  # config; core.pager above is what makes git actually use it.
  programs.delta = {
    enable = true;
    options = {
      # Options:
      #   true   n / N jump between files in a diff
      #   false  plain paging
      navigate = true;
      # Options:
      #   true   old and new side by side, like a GUI diff tool
      #   false  unified diff, one column
      side-by-side = true;
    };
  };
}
