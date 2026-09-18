# Remote Access

Reaching one of these machines from another: SSH for a shell, RustDesk for
the screen. What the repository manages is listed per section; the rest is
one-time setup on each machine, with the upstream docs as the source.

## SSH

Managed: the client configuration (`home/ssh/ssh.nix`; keys are added to the
agent on first use, Keychain on macOS via `home/ssh/darwin.nix`).

Managed too: a `Host` entry per tailnet machine with its user (`t14s`,
`spectre`, `mini`), so `ssh <name>` works from any of them. Machines are
named for their hardware, not their OS or role, so a name stays true through
a reinstall or a change of job; a second laptop gets its own model name.

Not managed, per machine:

- Anything else about hosts (LAN addresses, jump hosts, key paths):
  `~/.ssh/config.local`, which the managed config includes.
- Keys themselves. Generate on the machine; never in the repository.
- The SSH *server* on a machine you connect to. On Fedora the bootstrap
  enables `sshd`. On macOS: System Settings → General → Sharing → Remote
  Login. On a server, its own configuration.

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

### Connecting, and testing it

RustDesk is a GUI app on both ends; nothing happens in a terminal.

On the machine to be controlled (the Mac mini), once: RustDesk running (it
sits in the menu bar after the first launch), the macOS permissions above
granted, and Settings → Security → **Enable direct IP access** → Apply. Set a
permanent password there too, so connecting does not need someone at the
other end to click Accept.

On the controlling machine: tap Super (Fedora) and open RustDesk. In the
**ID** box, type the other machine's Tailscale IP (`tailscale ip -4 <name>`)
and click **Connect**; enter the password. A window opens showing the other
machine's screen.

To prove it works from anywhere, not just at home: do it once from a phone
hotspot, where the LAN path is gone and only Tailscale remains.

## Tailscale

The private network that makes SSH and RustDesk work between the machines
from anywhere. What it is and everything it can do: `docs/tailscale.md`.

Managed: the install, per OS (`platform/fedora/packages` and the daemon in
the Fedora bootstrap; the `tailscale-app` cask on the Mac). Not managed: the
machine's membership in the tailnet, which is a one-time login with your
account. On a Debian/Ubuntu server, Tailscale, hardening (ssh, firewall)
and updates are the [fleet](https://github.com/agosmou/fleet) repository's;
the platform step here only asserts `tailscaled` is running
(`docs/tailscale.md`, "Where it lives").

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

### Adding a machine

The facts this repository needs about a machine, so nothing has to be
remembered later:

1. Its **user** goes in its target file (`home.username`), before the first
   bootstrap. Home Manager refuses to activate under any other user. On the
   machine, `whoami` is the user and `hostname` is the name; those two
   values are the facts this repository needs.
2. Its **tailnet name and user** go in `home/ssh/ssh.nix` as a `Host` entry,
   so `ssh <name>` works from every other machine after they `just sync`.
   The name is the machine's hostname.
3. Bootstrap it, then `sudo tailscale up` (Linux) or the app (Mac).
4. If it is a machine you do not sit at: **disable key expiry** in the admin
   console.
5. From each machine that will connect to it: `ssh-copy-id <name>`, once.
   That copies the connecting machine's public key into the new machine's
   `~/.ssh/authorized_keys`; it asks for the new machine's password one time.
   `ssh-copy-id` is part of OpenSSH, shipped with Fedora (`openssh-clients`)
   and macOS; nothing to install.

### Renaming a machine

The hostname is the source of the name; everything else follows it.

Linux:

```bash
sudo hostnamectl set-hostname <new>
sudo systemctl restart tailscaled       # Tailscale re-reads the hostname; MagicDNS updates everywhere
```

macOS has three names, and Tailscale reads `HostName`, which About → Name
does not set. Set all three so they agree:

```bash
sudo scutil --set ComputerName "<new>"   # what Finder and Sharing show
sudo scutil --set LocalHostName "<new>"  # the Bonjour name (<new>.local)
sudo scutil --set HostName "<new>"       # what `hostname` and Tailscale report
```

If Tailscale on the Mac still shows the old name after that, make it re-register
under the new one: `sudo tailscale up --reset --hostname=<new>`. (`--hostname`
pins the tailnet name explicitly; with `HostName` set correctly, the plain
restart usually suffices.)

Verify on the machine itself: `hostname` prints the name, `whoami` prints the
user. Those two values are what go in `home/ssh/ssh.nix`.

Then change its `Host` entry there and `just sync` on every machine. Keys
need nothing: `authorized_keys` is not tied to the name. The first
`ssh <new>` from each machine asks to confirm the host key, once.

### Every day

```bash
tailscale status          # every machine; "direct" or "relay" per peer
tailscale ping <name>     # confirm a path to a machine
ssh <name>                # MagicDNS: the machine's hostname is its name
tailscale ip -4 <name>    # its 100.x.y.z address, for RustDesk
```

### When ssh fails

| Message | Meaning | Fix |
|---|---|---|
| `Could not resolve hostname` | The name is not on the tailnet (not logged in, or this machine is not) | `tailscale status` on both |
| `Connection refused` | Nothing is listening on port 22: the SSH server is off | Mac: Remote Login on. Fedora: `just sync` (bootstrap enables sshd). Debian/Ubuntu server: `sudo apt-get install openssh-server` |
| `Connection closed by <ip> port 22` | The server answered and rejected the user before authentication: that account does not exist there, or Remote Login is limited to other users | Use the account that exists (`whoami` on the machine); check Remote Login's "Allow access for" |
| `Permission denied (publickey,...)` | Right user, but this machine's key is not in its `authorized_keys` | `ssh-copy-id <name>` once |

### RustDesk over Tailscale

RustDesk's "direct IP access" connects to an IP instead of an ID, for any
machine you have network access to; Tailscale is that network access. On the
machine to be controlled: Settings → Security → **Enable direct IP access**,
apply (it listens on port 21118)
([RustDesk](https://github.com/rustdesk/rustdesk/discussions/8654)). On the
controlling machine, enter the other's Tailscale IP (`tailscale ip -4 <name>`)
in place of an ID. Traffic stays on the tailnet.
