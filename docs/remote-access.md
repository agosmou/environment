# Remote Access

Reaching one of these machines from another: SSH for a shell, RustDesk for
the screen. What the repository manages is listed per section; the rest is
one-time setup on each machine, with the upstream docs as the source.

## SSH

Managed: the client configuration (`home/ssh/ssh.nix`; keys are added to the
agent on first use, Keychain on macOS via `home/ssh/darwin.nix`).

Not managed, per machine:

- Hosts, usernames, jump hosts, key paths: `~/.ssh/config.local`, which the
  managed config includes.
- Keys themselves. Generate on the machine; never in the repository.
- The SSH *server* on a machine you connect to. On Fedora: `sudo systemctl
  enable --now sshd`. On macOS: System Settings → General → Sharing → Remote
  Login.

## RustDesk

Open-source remote desktop. Managed: the package, Linux via Home Manager
(`home/desktop/rustdesk.nix`), macOS via Homebrew (`platform/darwin/Brewfile`).

Not managed: the app's own settings, the unattended-access password, and the
macOS permissions below. Those stay on the machine.

### macOS one-time setup

Source: <https://rustdesk.com/docs/en/client/mac/>. Summary, in order:

1. `just bootstrap` installs the app into
   `/Applications` through Homebrew (the docs describe the manual .dmg drag;
   same result).
2. If Gatekeeper blocks the first launch: System Settings → Privacy &
   Security → allow apps from "App Store and identified developers".
3. Grant, in System Settings → Privacy & Security:
   - **Accessibility**: lets RustDesk control keyboard and mouse
   - **Screen Recording**: lets RustDesk capture the display
   - **Input Monitoring**: only if input still does not work on newer macOS
4. If a permission shows as granted but does not take effect, remove RustDesk
   from that list with the − button and re-add it with +.
5. Reboot if permissions still do not apply.

### Connecting

On the same network, RustDesk connects by ID through its rendezvous server
or directly by IP (enable "Direct IP access" in the receiving machine's
settings). Across networks, the plan is Tailscale: see below.

## Tailscale

Not set up yet. When it is, this section covers `tailscale up` on each
machine, `tailscale ping <name>` to verify, and connecting RustDesk to the
other machine's Tailscale IP so remote-desktop traffic never leaves the
private network.
