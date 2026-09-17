# just: the command runner. `just` with no arguments lists these recipes with
# the one-line comment directly above each. Every recipe is a thin wrapper
# over a nix or repository command, so the long invocations live here once
# instead of in shell history.
#
# Recipes run with bash in strict mode (-e stop on error, -u unset variables
# are errors, -o pipefail a failing command anywhere in a pipeline fails it).
set shell := ["bash", "-euo", "pipefail", "-c"]

# Directory containing this justfile, so recipes work from any cwd.
repo := justfile_directory()

# Which target this machine is. Home Manager records it at
# ~/.config/environment/target on every apply (see home/common.nix), so after
# the first bootstrap no recipe needs to be told. Pass a target explicitly to
# override, e.g. to build another machine's configuration.
target := `cat "$HOME/.config/environment/target" 2>/dev/null || true`

default:
  @just --list

# ---- The daily loop: edit, check, sync --------------------------------------
#
# sync is the one to type. apply, bootstrap, and doctor are the steps it is
# made of; each can be run alone to force just that step.

# Runs the checks in flake.nix: every target evaluates, the ones this machine
# can build are built, scripts are linted. "path:" reads uncommitted files.

# Check the repository; run before apply
check:
  nix flake check "path:{{repo}}"

# Same, for every system, building nothing. Catches an error in a Mac module
# while on Linux and vice versa.

# Check every target on every system (evaluate only)
check-all:
  nix flake check --all-systems --no-build "path:{{repo}}"

# Home Manager calls this "switch", as in switch to the new generation; the
# recipe is named for what it does to the machine.

# The one command for every machine, laptop included:
#   1. pull, if the tree is clean (with local edits in progress it skips
#      the pull and works with what is here)
#   2. decide: if anything under platform/ or in bootstrap itself differs
#      between the commit LAST APPLIED on this machine and the tree now
#      (committed or not), root-level work is needed, so bootstrap runs (it
#      asks for sudo and applies as part of its run); otherwise apply
#   3. remember the commit that was applied, for the next decision
#   4. doctor
# No prompts, so two machines syncing the same commit end up the same. The
# last-applied commit lives in ~/.local/state/environment/applied; with no
# record yet (first sync on a machine) it runs bootstrap, which is safe to
# repeat.

# Bring this machine up to date: pull, then bootstrap or apply as needed, then doctor
sync target=target:
  @[[ -n "{{target}}" ]] || { echo "no target recorded on this machine; pass one: just sync <target>" >&2; exit 1; }
  @cd "{{repo}}" && \
  echo "== sync: pull" && \
  if git diff --quiet && git diff --cached --quiet; then git pull --ff-only; else echo "local changes present; not pulling"; fi && \
  applied_file="$HOME/.local/state/environment/applied" && \
  applied="$(cat "$applied_file" 2>/dev/null || true)" && \
  if [[ -n "$applied" ]] && git cat-file -e "$applied" 2>/dev/null && git diff --quiet "$applied" -- platform bootstrap; then \
    echo "== sync: apply (nothing root-level changed since ${applied:0:7})" && just apply "{{target}}"; \
  else \
    echo "== sync: bootstrap (platform/ or bootstrap changed, or first sync; asks for sudo)" && just bootstrap "{{target}}"; \
  fi && \
  mkdir -p "$(dirname "$applied_file")" && git rev-parse HEAD > "$applied_file" && \
  echo "== sync: doctor" && \
  if just doctor "{{target}}"; then \
    echo "== sync: done. This machine matches the repository."; \
  else \
    echo "== sync: done. The machine is up to date; doctor listed something to look at above."; \
  fi

# One step of sync: build and activate a new Home Manager generation, no
# pull, no bootstrap decision. Run alone to force a rebuild.

# Apply the repository to this machine (build and activate a new generation)
apply target=target:
  @[[ -n "{{target}}" ]] || { echo "no target recorded on this machine; pass one: just apply <target>" >&2; exit 1; }
  nix run "path:{{repo}}#home-manager" -- switch --flake "path:{{repo}}#ag@{{target}}"

# Read-only: missing tools, stale symlinks, packages installed by hand
# outside the manifests.

# Compare this machine against the repository
doctor target=target:
  @[[ -n "{{target}}" ]] || { echo "no target recorded on this machine; pass one: just doctor <target>" >&2; exit 1; }
  "{{repo}}/scripts/doctor" "{{target}}"

# Read-only: Home Manager packages and files, the root-level manifest for
# the target's OS, the repository tree.

# Print everything a target declares
inventory target=target:
  @[[ -n "{{target}}" ]] || { echo "no target recorded on this machine; pass one: just inventory <target>" >&2; exit 1; }
  "{{repo}}/scripts/inventory" "{{target}}"

# ---- Less often ---------------------------------------------------------------

# Build a target without activating it (result in ./result)
build target=target:
  @[[ -n "{{target}}" ]] || { echo "no target recorded on this machine; pass one: just build <target>" >&2; exit 1; }
  nix build 'path:{{repo}}#homeConfigurations."ag@{{target}}".activationPackage'

# One step of sync, run when anything under platform/ changed (dnf packages,
# keyd, Brewfile). Asks for sudo. Run alone to force it.

# Apply the root-level layer again
bootstrap target=target:
  @[[ -n "{{target}}" ]] || { echo "no target recorded on this machine; pass one: just bootstrap <target>" >&2; exit 1; }
  "{{repo}}/bootstrap" --repo-dir "{{repo}}" --target "{{target}}"

# ---- When something is wrong ------------------------------------------------

# Every apply makes a generation and keeps the old ones, so undoing a bad
# apply is activating the previous generation. Nothing is rebuilt. The
# repository is unchanged; fix it, then apply again.

# Go back to the previous Home Manager generation
rollback:
  previous="$(nix run "path:{{repo}}#home-manager" -- generations | sed -n 2p | awk '{print $NF}')"; \
  [[ -n "$previous" ]] || { echo "no previous generation" >&2; exit 1; }; \
  echo "activating $previous"; "$previous/activate"

# List every Home Manager generation on this machine, newest first
generations:
  nix run "path:{{repo}}#home-manager" -- generations

# ---- Updating packages --------------------------------------------------------

# flake.lock pins the exact nixpkgs and home-manager commits, so nothing
# changes version until this is run. Afterwards: check, apply, use the
# machine for a bit, then commit flake.lock. If something broke: rollback,
# `git checkout flake.lock`, apply.

# Update flake.lock to the newest nixpkgs and home-manager
update:
  nix flake update --flake "{{repo}}"

# ---- Before committing --------------------------------------------------------

# Format every .nix file
fmt:
  shopt -s globstar nullglob; cd "{{repo}}"; nix fmt -- **/*.nix

# Scan the working tree for anything that looks like a secret or token
secrets:
  nix run nixpkgs#gitleaks -- detect --source "{{repo}}" --no-git --redact
