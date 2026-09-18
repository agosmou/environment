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

Open-source remote desktop. Managed: the package, from RustDesk's own builds
on both platforms: the rpm from its GitHub release on Fedora
(`platform/fedora/packages`), the Homebrew cask on macOS
(`platform/darwin/Brewfile`).

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

The private network that makes SSH and RustDesk work between the machines
from anywhere. What it is and everything it can do: `docs/tailscale.md`.

Managed: the install, per OS (`platform/fedora/packages` and the daemon in
the Fedora bootstrap; the `tailscale-app` cask on the Mac). Not managed: the
machine's membership in the tailnet, which is a one-time login with your
account. On a Debian/Ubuntu server, `platform/debian/packages` and its
bootstrap install it the same way (Tailscale's apt repository). Hardening
(ssh, firewall) is the server's own configuration, not this repository.

### One-time, per machine

1. Join the tailnet. Linux: `sudo tailscale up` prints a URL; open it and log
   in with the account the tailnet belongs to. Mac: log in from the Tailscale
   menu-bar app. `tailscale up` is "Connect your device to Tailscale and
   authenticate if needed" ([CLI reference](https://tailscale.com/kb/1080/cli)).
2. For a machine you reach but rarely sit at (a server, the Mac mini):
   disable key expiry, or it silently drops off the tailnet after 180 days.
   Admin console → Machines → the machine's menu → **Disable key expiry**.
   Tailscale recommends this for "trusted servers ... that are hard to reach"
   ([key expiry](https://tailscale.com/kb/1028/key-expiry)).
3. To SSH *into* a Mac, macOS must allow it: System Settings → General →
   Sharing → Remote Login, on ([Apple](https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac)).

The tailnet is administered in a browser at <https://login.tailscale.com/admin>:
the machines list, names, key expiry, the policy file.

### Every day

```bash
tailscale status          # every machine; "direct" or "relay" per peer
tailscale ping <name>     # confirm a path to a machine
ssh <name>                # MagicDNS: the machine's hostname is its name
tailscale ip -4 <name>    # its 100.x.y.z address, for RustDesk
```

### RustDesk over Tailscale

RustDesk's "direct IP access" connects to an IP instead of an ID, for any
machine you have network access to; Tailscale is that network access. On the
machine to be controlled: Settings → Security → **Enable direct IP access**,
apply (it listens on port 21118)
([RustDesk](https://github.com/rustdesk/rustdesk/discussions/8654)). On the
controlling machine, enter the other's Tailscale IP (`tailscale ip -4 <name>`)
in place of an ID. Traffic stays on the tailnet.
