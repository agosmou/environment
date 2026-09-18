#!/usr/bin/env bash
#
# Debian/Ubuntu platform step, run by ./bootstrap after Home Manager has
# activated. Everything here needs root.
#
#   platform/debian/bootstrap.sh <repo-dir> <target>
#
# What it does:
#   1. add vendor apt repositories, then apt-get install everything listed in
#      platform/debian/packages
#   2. enable the Tailscale daemon
#
# Runs for every target (a Linux server is the usual case). Every step is
# idempotent: re-running refreshes what changed and leaves the rest alone.

set -euo pipefail

repo_dir="${1:-$HOME/environment}"
# The target is accepted for symmetry with the Fedora step; every target
# gets the same root-level packages here, so it is only echoed.
target="${2:-server-x86_64-linux}"
printf 'Debian/Ubuntu platform setup for %s\n' "$target"

command -v sudo >/dev/null 2>&1 || {
  printf 'Debian/Ubuntu setup requires sudo.\n' >&2
  exit 1
}

# Distribution id and release codename (e.g. ubuntu / resolute), which vendor
# repositories are published per. Read in a subshell so /etc/os-release's
# variables do not leak into this script.
# shellcheck disable=SC1091
distro="$(. /etc/os-release && printf '%s' "$ID")"
# shellcheck disable=SC1091
codename="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"

# ---- 1. Root-level packages -------------------------------------------------

# Vendor package repositories.
#
# What a repository is: apt installs packages from a list of sources under
# /etc/apt/sources.list.d/, each signed by a key kept under
# /usr/share/keyrings/. A vendor that hosts its own repository publishes both
# files; add them once, and from then on the vendor's package installs with
# apt-get install and updates with apt-get upgrade like any other, every
# download checked against the vendor's key. Each is skipped when its
# sources file is already present, so re-running is safe.

# Tailscale. Tailscale hosts this repository itself (pkgs.tailscale.com) and
# publishes a keyring and a sources file per distribution release. These
# are the exact steps of the apt branch of Tailscale's own installer
# (https://tailscale.com/install.sh): keyring, sources list, apt-get update,
# install tailscale plus the keyring package that keeps the key current.
if [[ ! -f /etc/apt/sources.list.d/tailscale.list ]]; then
  sudo mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.noarmor.gpg" |
    sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  sudo chmod 0644 /usr/share/keyrings/tailscale-archive-keyring.gpg
  curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.tailscale-keyring.list" |
    sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  sudo chmod 0644 /etc/apt/sources.list.d/tailscale.list
fi

# The list lives in platform/debian/packages so doctor and inventory can read
# the same file. `grep -v` drops comment lines and blank lines; `mapfile -t`
# turns the remaining lines into a bash array, one package per element.
mapfile -t packages < <(grep -v -E '^[[:space:]]*(#|$)' "$repo_dir/platform/debian/packages")

if ((${#packages[@]} > 0)); then
  # DEBIAN_FRONTEND=noninteractive: never stop on a configuration prompt.
  # apt skips packages that are already installed, so this is a no-op on
  # re-runs unless the list changed. tailscale-archive-keyring keeps
  # Tailscale's signing key updated through apt itself.
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" tailscale-archive-keyring
fi

# ---- 2. Tailscale daemon ------------------------------------------------------

# The package installs tailscaled but does not start it; Tailscale's installer
# ends with this same line. Joining the tailnet is a separate one-time
# interactive step (`sudo tailscale up` opens a browser), deliberately not
# automated: it needs your account. doctor reminds you.
sudo systemctl enable --now tailscaled

printf 'Debian/Ubuntu platform setup complete.\n'
