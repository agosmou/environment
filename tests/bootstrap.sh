#!/usr/bin/env bash
#
# Tests for ./bootstrap's target detection. Runs as a flake check, so
# `nix flake check` fails if a change to bootstrap breaks how it decides
# which machine it is on.
#
# Two paths are exercised, both of which stop before installing anything:
#   --dry-run  the script resolves and validates the target and prints it.
#              ENVIRONMENT_BOOTSTRAP_UNAME_* make it believe it is on a
#              different CPU or OS than the one running the test.
#   ENVIRONMENT_BOOTSTRAP_TEST_HOME_FILES
#              the script runs only its symlink step against a scratch HOME
#              and a fake generation tree, then exits.

set -euo pipefail

bootstrap="${BOOTSTRAP:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bootstrap}"
tests=0

# Run bootstrap --dry-run pretending to be on <machine> <os>, asking for
# <requested>. Prints "system=... target=...".
resolve() {
  local machine="$1"
  local os="$2"
  local requested="$3"

  ENVIRONMENT_BOOTSTRAP_UNAME_M="$machine" \
    ENVIRONMENT_BOOTSTRAP_UNAME_S="$os" \
    bash "$bootstrap" --dry-run --target "$requested"
}

# Assert that resolve(...) picks the expected full target name.
expect_target() {
  local expected="$1"
  shift
  local output

  output="$(resolve "$@")"
  [[ "$output" == *"target=$expected"* ]] || {
    printf 'expected %s, got:\n%s\n' "$expected" "$output" >&2
    exit 1
  }
  ((tests += 1))
}

# Assert that resolve(...) refuses.
expect_failure() {
  if resolve "$@" >/dev/null 2>&1; then
    printf 'expected target resolution to fail: %s\n' "$*" >&2
    exit 1
  fi
  ((tests += 1))
}

#             expected target            uname -m  uname -s  --target
expect_target workstation-x86_64-linux   x86_64    Linux     workstation
expect_target workstation-x86_64-linux   amd64     Linux     workstation
expect_target workstation-aarch64-darwin arm64     Darwin    workstation
expect_target server-x86_64-linux        x86_64    Linux     server
expect_target server-aarch64-linux       aarch64   Linux     server
expect_target server-aarch64-linux       arm64     Linux     server-aarch64-linux

# Wrong machine for the named target, unsupported hardware or OS, typo.
expect_failure x86_64  Linux   server-aarch64-linux
expect_failure aarch64 Linux   workstation
expect_failure riscv64 Linux   server
expect_failure x86_64  FreeBSD server
expect_failure x86_64  Linux   unknown

# ---- Symlinks from a previous dotfiles setup --------------------------------
#
# Home Manager refuses to replace a symlink, so bootstrap moves foreign ones
# aside first. Build a scratch HOME that has, in the way of managed files:
#   ~/.zshrc                  a symlink into ~/dotfiles     -> moved aside
#   ~/.config/nvim            a symlinked directory         -> moved aside whole
#   ~/.config/git/config      a symlink into /nix/store     -> left alone
#   ~/.config/tmux/tmux.conf  a regular file                -> left alone (-b handles it)
# and a fake generation tree listing those four paths.
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
home="$scratch/home"
files="$scratch/home-files"
mkdir -p "$home/dotfiles/nvim" "$home/.config/git" "$home/.config/tmux" \
  "$files/.config/nvim" "$files/.config/git" "$files/.config/tmux"
touch "$home/dotfiles/.zshrc" "$home/dotfiles/nvim/init.lua" "$home/.config/tmux/tmux.conf"
ln -s "$home/dotfiles/.zshrc" "$home/.zshrc"
ln -s "$home/dotfiles/nvim" "$home/.config/nvim"
ln -s /nix/store/0000000000000000000000000000000-home-manager-files/.config/git/config "$home/.config/git/config"
touch "$files/.zshrc" "$files/.config/nvim/init.lua" "$files/.config/git/config" "$files/.config/tmux/tmux.conf"

HOME="$home" ENVIRONMENT_BOOTSTRAP_TEST_HOME_FILES="$files" bash "$bootstrap" >/dev/null

expect_moved() {
  [[ -L "$1.pre-home-manager" && ! -e "$1" && ! -L "$1" ]] || {
    printf 'expected %s to be moved to %s.pre-home-manager\n' "$1" "$1" >&2
    ls -la "$(dirname "$1")" >&2
    exit 1
  }
  ((tests += 1))
}
expect_untouched() {
  [[ -e "$1" || -L "$1" ]] && [[ ! -e "$1.pre-home-manager" && ! -L "$1.pre-home-manager" ]] || {
    printf 'expected %s to be left alone\n' "$1" >&2
    ls -la "$(dirname "$1")" >&2
    exit 1
  }
  ((tests += 1))
}
expect_moved "$home/.zshrc"
expect_moved "$home/.config/nvim"
expect_untouched "$home/.config/git/config"
expect_untouched "$home/.config/tmux/tmux.conf"
# The dotfiles themselves are never touched.
[[ -f "$home/dotfiles/.zshrc" && -f "$home/dotfiles/nvim/init.lua" ]] || {
  printf 'dotfiles directory was modified\n' >&2
  exit 1
}
((tests += 1))

printf 'bootstrap tests passed: %d\n' "$tests"
