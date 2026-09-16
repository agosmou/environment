#!/usr/bin/env bash
#
# macOS platform step, run by ./bootstrap after Home Manager has activated.
#
#   platform/darwin/bootstrap.sh <repo-dir> <target>
#
# Installs Homebrew if it is missing, then applies platform/darwin/Brewfile:
# the native applications that either are not in nixpkgs for Apple Silicon
# or are better as signed .app bundles (Ghostty, RustDesk). Everything
# command-line comes from Home Manager, not Homebrew.
#
# Re-runs are safe: `brew bundle` skips what is already installed.

set -euo pipefail

repo_dir="${1:-$HOME/environment}"
target="${2:-workstation-aarch64-darwin}"

# A headless Mac would not want GUI applications. There is no such target
# today; the check is here so a future one does the right thing.
if [[ "$target" != workstation-* ]]; then
  printf 'No macOS application steps are required for %s.\n' "$target"
  exit 0
fi

# Find brew. It is not on PATH in a fresh shell until its shellenv is loaded,
# so check the two places Homebrew installs itself (Apple Silicon, Intel).
if command -v brew >/dev/null 2>&1; then
  brew_bin="$(command -v brew)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  brew_bin=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
  brew_bin=/usr/local/bin/brew
else
  command -v curl >/dev/null 2>&1 || {
    printf 'Installing Homebrew requires curl.\n' >&2
    exit 1
  }

  # Homebrew's official installer. NONINTERACTIVE skips its "press Enter"
  # prompt; it still asks for the sudo password.
  printf 'Installing Homebrew...\n'
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin=/usr/local/bin/brew
  else
    printf 'Homebrew installed but its executable was not found.\n' >&2
    exit 1
  fi
fi

# Install everything in the Brewfile that is not installed yet.
"$brew_bin" bundle --file "$repo_dir/platform/darwin/Brewfile"

printf 'macOS application setup complete for %s.\n' "$target"
printf 'Grant RustDesk its requested macOS privacy permissions in System Settings.\n'
