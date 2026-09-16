# Shell aliases shared by bash (Linux) and zsh (macOS).
#
# Only shortcuts that get typed daily. A git alias you have to look up is
# slower than typing the command, so anything not obviously useful is left
# out; add one when you notice yourself typing the long form repeatedly.
{
  # Git: status and history
  g = "git";
  gst = "git status";
  glog = "git log --oneline --graph --decorate"; # one line per commit, with branch graph
  gl10 = "git log --oneline -10"; # the last ten commits

  # Git: staging and committing
  ga = "git add";
  gaa = "git add --all";
  gd = "git diff"; # unstaged changes
  gds = "git diff --staged"; # what the next commit will contain
  gc = "git commit";
  gcm = "git commit -m";

  # Git: branches and worktrees
  gs = "git switch";
  gsc = "git switch -c"; # create a branch and switch to it
  gb = "git branch";
  gw = "git worktree";
  gwl = "git worktree list";

  # Git: remotes
  gp = "git push";
  gpl = "git pull --rebase";
  gfa = "git fetch --all --prune"; # update every remote; forget branches deleted remotely

  # Navigation and tools
  ll = "eza -lah --icons --git"; # long listing with hidden files and git status
  la = "eza -a --icons";
  v = "nvim";
  lg = "lazygit";
  ".." = "cd ..";
  "..." = "cd ../..";
}
