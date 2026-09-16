#!/usr/bin/env bash
#
# Tests for ./bootstrap's target detection. Runs as a flake check, so
# `nix flake check` fails if a change to bootstrap breaks how it decides
# which machine it is on.
#
# Only the --dry-run path is exercised: the script resolves and validates the
# target, prints it, and exits before installing anything. The
# ENVIRONMENT_BOOTSTRAP_UNAME_* variables make it believe it is on a
# different CPU or OS than the one running the test.

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

printf 'bootstrap target tests passed: %d\n' "$tests"
