# Tailscale

A private network between your own machines, over the internet, that behaves
as if they were all on one LAN. Not a Nix thing: it is a system daemon,
installed by the OS's package manager and managed in `platform/`.

Every claim below links to Tailscale's own documentation.

## What it is

Tailscale's definition: a "connectivity platform" that "connects remote teams,
multi-cloud environments, CI/CD pipelines, Edge & IoT devices" over "a
peer-to-peer mesh network" with "end-to-end encryption", built on "WireGuard,
a state-of-the-art VPN protocol known for its security and performance"
([What is Tailscale](https://tailscale.com/kb/1151/what-is-tailscale)).

Your machines together are a **tailnet**. Each gets a stable IP in
`100.x.y.z` and a name.

## How it works

From Tailscale's own explanation ([How Tailscale works](https://tailscale.com/blog/how-tailscale-works)):

| Piece | What it does |
|---|---|
| WireGuard | The tunnel between any two of your machines. Traffic is "end-to-end encrypted": "only the two nodes that are communicating with each other are able to encrypt or decrypt packets." |
| Coordination server (Tailscale's) | A key exchange: each machine "leaves its public key and a note about where that node can currently be found", and "downloads a list of public keys and addresses" of the others. "The private key never, ever leaves its node", so the server cannot read traffic. |
| NAT traversal | Gets two machines behind two home routers talking directly, "based on the Internet STUN and ICE standards", with no port forwarding. |
| DERP relays | Fallback for "especially cruel networks" that "block UDP entirely": traffic relays through Tailscale's servers, still encrypted; "it's impossible for a DERP server to decrypt your traffic" ([DERP servers](https://tailscale.com/kb/1232/derp-servers)). |

## Everything it can do

The feature areas Tailscale documents ([docs index](https://tailscale.com/kb/1017/install)), each with its one-line definition from the linked page:

| Feature | What it is | Relevant here? |
|---|---|---|
| [MagicDNS](https://tailscale.com/kb/1081/magicdns) | "Automatically registers DNS names for devices in your network": `<name>`, or `<name>.<tailnet>.ts.net`. On by default for tailnets created after October 2022. | Yes: `ssh <name>` |
| [Access control policies](https://tailscale.com/kb/1018/acls) | Who may reach what: "a set of devices or users who can access ports on other devices." A new tailnet's "default tailnet policy file enables communication between all devices." | Later, if the tailnet grows beyond your own machines |
| [Exit nodes](https://tailscale.com/kb/1103/exit-nodes) | Route all of a machine's internet traffic through another machine: "The device routing your traffic is called an exit node." Advertise with `sudo tailscale set --advertise-exit-node`; use with `sudo tailscale set --exit-node=<name>`; an admin must approve the node. | Yes: appear to be at home while travelling |
| [Mullvad exit nodes](https://tailscale.com/kb/1258/mullvad-exit-nodes) | Add-on: "lets you use Mullvad VPN servers as exit nodes in a Tailscale network." Paid, enabled in the admin console; `tailscale exit-node list` shows them. Tailscale's guide says to disable the standalone Mullvad app when migrating. | Yes: a chosen exit location without a second VPN app |
| [Subnet routers](https://tailscale.com/kb/1019/subnets) | "A device in your tailnet that you use as a gateway to advertise routes to other devices. This lets devices connect to your tailnet without installing the Tailscale client." | Maybe: reach a printer or NAS at home that cannot run Tailscale |
| [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh) | "Lets Tailscale manage the authentication and authorization of SSH connections in your tailnet": identity instead of key files, controlled by the policy file. `tailscale set --ssh` on the server. | Optional; ordinary SSH keys over the tailnet are enough for now |
| [Serve](https://tailscale.com/kb/1312/serve) | "Route traffic from other devices on your Tailscale network to a local service running on your device": `tailscale serve 3000` gives a dev server an HTTPS URL on the tailnet. | Yes: show a dev server to the Mac or a phone |
| [Funnel](https://tailscale.com/kb/1223/funnel) | The same, but "publicly over the internet." | Occasionally: a demo for someone outside |
| [Taildrop](https://tailscale.com/kb/1106/taildrop) | "Send files between your personal devices": `tailscale file cp <file> <name>:` | Handy: laptop to Mac without a cloud |
| [Tailnet Lock](https://tailscale.com/kb/1226/tailnet-lock) | "Verify that no node joins your tailnet unless trusted nodes in your tailnet sign the new node": protection even "if Tailscale were malicious or Tailscale infrastructure hacked." | No, for a personal tailnet |
| [App connectors](https://tailscale.com/kb/1281/app-connectors) | "Route your self-hosted applications and SaaS applications through dedicated devices in your tailnet." | No |
| Device management, system policies, logging and auditing | Fleet administration for organizations. | No |

## What it solves here

1. **SSH to a server from anywhere.** `ssh <server>` from any of your
   machines, on any network, with no port opened on the server's router and
   nothing exposed to the internet. The server's firewall can allow SSH only
   from the local network and from `tailscale0`.
2. **RustDesk across networks.** Without Tailscale, RustDesk reaches another
   machine directly only on the same LAN. Over the tailnet it reaches it from
   anywhere, by its Tailscale IP.
3. **A dev server, from any device.** A service on `<server>:3000` is
   reachable from every machine on the tailnet, including a phone; or
   `tailscale serve` gives it an HTTPS URL.
4. **Exit nodes.** Route a machine's internet traffic through another of your
   machines, or through a Mullvad location via the add-on.

## Where it lives in this repository

| Machine | Installed by | Declared in |
|---|---|---|
| Fedora laptop | Tailscale's own dnf repository (`pkgs.tailscale.com/stable/fedora`), which is what [Tailscale's installer](https://tailscale.com/download/linux/fedora) adds on Fedora; Fedora's own package lags a few releases. The bootstrap adds the repo and enables `tailscaled`. | `platform/fedora/packages`, `platform/fedora/bootstrap.sh` |
| Mac | Homebrew cask `tailscale-app`, which installs the **Standalone** `.pkg` from `pkgs.tailscale.com`, the variant Tailscale "always recommend[s]" ([macOS variants](https://tailscale.com/kb/1065/macos-variants)); it includes the `tailscale` command. | `platform/darwin/Brewfile` |
| A server managed by Ansible | Tailscale's own apt or dnf repository. | that repository's `tailscale` role |

Home Manager has no part in it. There is no config file to manage: the
daemon's state in `/var/lib/tailscale` is the machine's identity and stays on
the machine.

## Setting it up

Once per machine, after the first `just sync` (or after the server's own
configuration has installed it):

```bash
sudo tailscale up          # prints a URL; open it, log in; the machine joins
tailscale status           # every machine on the tailnet, with IPs and names
```

On the Mac, open the Tailscale app from the menu bar and log in instead.
`just doctor` reports a machine that is installed but not logged in.

The tailnet is administered at <https://login.tailscale.com/admin>: machines,
names, the policy file, key expiry, exit node approval.

## Using it

```bash
tailscale status                       # who is on the tailnet; direct or relayed
tailscale ping <name>                  # confirm a path to a machine
ssh <name>                             # MagicDNS name; also ssh <user>@<name>
tailscale ip -4 <name>                 # the 100.x.y.z address, e.g. for RustDesk
tailscale file cp report.pdf <name>:   # Taildrop
tailscale serve 3000                   # dev server, HTTPS, tailnet only
sudo tailscale set --exit-node=<name>  # route everything through that machine; --exit-node= to stop
```

RustDesk: on the receiving machine enable "Direct IP access" in its settings;
on the connecting machine enter the other's Tailscale IP.

## Mullvad and Tailscale together

Mullvad's own app, in its default full-tunnel mode, routes everything through
Mullvad and blocks the rest, which cuts off tailnet peers. Either run one at a
time (Mullvad for public wifi, Tailscale to reach your machines), or use
Tailscale's [Mullvad exit nodes](https://tailscale.com/kb/1258/mullvad-exit-nodes),
which give the Mullvad location while staying on the tailnet; Tailscale's own
guide says to disable the standalone app in that case.
