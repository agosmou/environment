#!/usr/bin/env bash
#
# Debian/Ubuntu platform step, run by ./bootstrap after Home Manager has
# activated.
#
#   platform/debian/bootstrap.sh <repo-dir> <target>
#
# Every Debian/Ubuntu machine here is a server, and a server's root layer
# belongs to the fleet repository (github.com/agosmou/fleet): cloud-init
# installs and joins Tailscale at first boot, ansible hardens and checks.
# This step therefore WRITES NOTHING under /etc or apt. It only:
#   1. apt-get installs whatever platform/debian/packages lists (empty
#      today; the mechanism stays for a root package the user layer might
#      one day need)
#   2. asserts that tailscaled is running, since `ssh <name>` between
#      machines depends on it, and says where to look if it is not
#
# Fedora and macOS are different: no other repository touches root there,
# so their platform steps do install Tailscale.

set -euo pipefail

repo_dir="${1:-$HOME/environment}"
# The target is accepted for symmetry with the Fedora step; every target
# gets the same treatment here, so it is only echoed.
target="${2:-server-x86_64-linux}"
printf 'Debian/Ubuntu platform setup for %s\n' "$target"

command -v sudo >/dev/null 2>&1 || {
  printf 'Debian/Ubuntu setup requires sudo.\n' >&2
  exit 1
}

# ---- 1. Root-level packages the user layer needs --------------------------------

# The list lives in platform/debian/packages so doctor and inventory can read
# the same file. `grep -v` drops comment lines and blank lines; `mapfile -t`
# turns the remaining lines into a bash array, one package per element.
mapfile -t packages < <(grep -v -E '^[[:space:]]*(#|$)' "$repo_dir/platform/debian/packages")

if ((${#packages[@]} > 0)); then
  # DEBIAN_FRONTEND=noninteractive: never stop on a configuration prompt.
  # apt skips packages that are already installed, so this is a no-op on
  # re-runs unless the list changed.
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
fi

# ---- 2. Tailscale: assert, do not install ----------------------------------------

# Installed and joined by fleet (cloud-init at birth; `sudo tailscale up`
# by hand on a machine built before that existed). If it is not running,
# this is the wrong repository to fix it from.
if systemctl is-active --quiet tailscaled; then
  printf 'tailscaled is running.\n'
else
  cat >&2 <<'MSG'
tailscaled is not running. On a server, Tailscale is the fleet repository's
job, not this one's:
  born via cloud-init?  sudo cloud-init status --long
  built by hand?        curl -fsSL https://tailscale.com/install.sh | sh
                        sudo tailscale up
Then re-run this step.
MSG
  exit 1
fi

printf 'Debian/Ubuntu platform setup complete.\n'
