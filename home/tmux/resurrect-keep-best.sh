# resurrect-keep-best: keep tmux-resurrect's `last` pointer on a useful snapshot.
#
# Runs as the @resurrect-hook-post-save-all hook. tmux-continuum auto-saves on
# a timer, so a fresh or nearly empty server (after kill-server, or before
# auto-restore finished) can be saved over a good snapshot and `last` repointed
# at it. A later restore then brings back almost nothing.
#
# If the snapshot just written has fewer than MIN_PANES pane records and a
# recent snapshot with at least MIN_PANES exists, `last` is pointed back at
# that snapshot. The tiny file stays on disk; resurrect's own retention
# (keep 5, delete after 30 days) cleans it up.
#
# Tunables (tmux user options):
#   @resurrect-keep-best-min-panes   default 2
#   @resurrect-keep-best-max-age     default 7 (days; older snapshots are ignored)
#
# Snapshot state is on disk only. This protects the pointer, not process memory
# or unsaved buffers, and cannot make kill-server safe.

tmux_opt() {
  local value
  value="$(tmux show-option -gqv "$1" 2>/dev/null || true)"
  printf '%s' "${value:-$2}"
}

min_panes="$(tmux_opt @resurrect-keep-best-min-panes 2)"
max_age_days="$(tmux_opt @resurrect-keep-best-max-age 7)"

resurrect_dir="$(tmux_opt @resurrect-dir "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect")"
resurrect_dir="${resurrect_dir/#\~/$HOME}"
last_link="$resurrect_dir/last"

[[ -L "$last_link" ]] || exit 0

lock_dir="$resurrect_dir/.keep-best.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir" 2>/dev/null' EXIT

count_panes() {
  local n
  n="$(grep -c '^pane' "$1" 2>/dev/null || true)"
  printf '%s' "${n:-0}"
}

current="$resurrect_dir/$(readlink "$last_link")"
[[ -f "$current" ]] || exit 0

if (( $(count_panes "$current") >= min_panes )); then
  exit 0
fi

best=""
while IFS= read -r candidate; do
  [[ "$candidate" == "$current" ]] && continue
  if (( $(count_panes "$candidate") >= min_panes )); then
    best="$candidate"
    break
  fi
done < <(find "$resurrect_dir" -maxdepth 1 -name 'tmux_resurrect_*.txt' \
  -mtime "-$max_age_days" -print0 | xargs -0 ls -t 2>/dev/null)

if [[ -n "$best" ]]; then
  ln -sfn "$(basename "$best")" "$last_link"
  tmux display-message "resurrect: kept $(basename "$best") as last (new save had too few panes)"
fi
