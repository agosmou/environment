#!/usr/bin/env bash
#
# Fedora platform step, run by ./bootstrap after Home Manager has activated.
# Everything here needs root; nothing else in the repository does.
#
#   platform/fedora/bootstrap.sh <repo-dir> <target>
#
# What it does:
#   1. dnf install everything listed in platform/fedora/packages
#   2. install the tmpfiles rule that lets Nix-built GUI apps find the GPU
#   3. install the keyd key-remapping daemon as a system service
#   4. install the battery charge-limit rule
#
# Every step is idempotent: re-running after a package update or a config
# change refreshes what changed and leaves the rest alone.

set -euo pipefail

repo_dir="${1:-$HOME/environment}"
target="${2:-workstation-x86_64-linux}"

# Servers have no GPU to integrate and no keyboard to remap.
if [[ "$target" != workstation-* ]]; then
  printf 'No privileged Fedora steps are required for %s.\n' "$target"
  exit 0
fi

command -v sudo >/dev/null 2>&1 || {
  printf 'Fedora workstation setup requires sudo.\n' >&2
  exit 1
}

# ---- 1. Root-level packages -------------------------------------------------

# The list lives in platform/fedora/packages so doctor and inventory can read
# the same file. `grep -v` drops comment lines and blank lines; `mapfile -t`
# turns the remaining lines into a bash array, one package per element. A
# line can be a package name or the URL of an rpm; dnf installs both.
mapfile -t packages < <(grep -v -E '^[[:space:]]*(#|$)' "$repo_dir/platform/fedora/packages")

if ((${#packages[@]} > 0)); then
  # dnf skips packages that are already installed, so this is a no-op on
  # re-runs unless the list changed.
  sudo dnf install -y "${packages[@]}"
fi

# ---- 2. GPU access for Nix-built GUI apps -----------------------------------

# Nix-built programs look for OpenGL/Vulkan drivers in /run/opengl-driver,
# a NixOS convention. Fedora keeps its Mesa drivers elsewhere. Home Manager's
# genericLinux target generates a small script that writes a tmpfiles.d rule
# pointing /run/opengl-driver at Fedora's drivers, recreated on every boot.
# Without this, Ghostty (the one Nix-built GUI app here) falls back to
# software rendering or fails to start. This is the setup Ghostty's own docs
# describe for Home Manager on non-NixOS.
gpu_setup="$HOME/.nix-profile/bin/non-nixos-gpu-setup"
if [[ -x "$gpu_setup" ]]; then
  sudo "$gpu_setup"
fi

# ---- 3. keyd, the key remapping daemon ---------------------------------------

# keyd remaps keys below the desktop (see platform/fedora/keyd/default.conf
# for what), so it must run as root and as a system service.
#
# The binary comes from Home Manager (home/desktop/keyd.nix), but a systemd
# system service cannot execute it from /nix/store: Fedora's SELinux policy
# forbids system services from running files with the generic label the Nix
# store gets. So the binary is copied to /usr/local/bin, where `restorecon`
# gives it the normal bin_t label, and the service runs that copy. Re-running
# this script after a keyd update refreshes the copy.
keyd_bin="$HOME/.nix-profile/bin/keyd"
keyd_config="$repo_dir/platform/fedora/keyd/default.conf"
keyd_service="$repo_dir/platform/fedora/keyd/keyd.service"

[[ -x "$keyd_bin" ]] || {
  printf 'Home Manager did not install keyd at %s.\n' "$keyd_bin" >&2
  exit 1
}

# Validate the config before touching the system; a bad mapping can make the
# keyboard unusable. (If that ever happens: Backspace+Escape+Enter kills keyd.)
"$keyd_bin" check "$keyd_config"

# keyd expects a `keyd` group for its control socket.
getent group keyd >/dev/null || sudo groupadd --system keyd

# `install` copies a file and sets its mode in one step; -d makes a directory.
sudo install -d -m 0755 /etc/keyd
sudo install -m 0644 "$keyd_config" /etc/keyd/default.conf
sudo install -m 0755 "$keyd_bin" /usr/local/bin/keyd-nix
sudo restorecon /usr/local/bin/keyd-nix
sudo install -m 0644 "$keyd_service" /etc/systemd/system/keyd.service

# Tell systemd the unit file changed, clear any earlier failure, start it now
# and at every boot.
sudo systemctl daemon-reload
sudo systemctl reset-failed keyd.service
sudo systemctl enable --now keyd.service

# ---- 4. Battery charge limit -----------------------------------------------

# A tmpfiles.d rule (platform/fedora/battery.conf) writes the firmware's
# charge thresholds at boot. `systemd-tmpfiles --create` applies it now too,
# so the limit takes effect without a reboot. On a machine without a battery
# the rule's paths are missing and tmpfiles skips them with a warning.
sudo install -m 0644 "$repo_dir/platform/fedora/battery.conf" /etc/tmpfiles.d/environment-battery.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/environment-battery.conf || true

printf 'Fedora platform setup complete.\n'
