# Containers

Who has what, why, and exactly what to change when the Fedora laptop
should get Docker.

## Today

| Machine | Runtime | Installed by | `docker` command |
|---|---|---|---|
| Mac mini | Docker Desktop | `platform/darwin/Brewfile` | yes |
| spectre, droplets (Ubuntu) | Docker CE | fleet, `roles/docker`, inventory group `containers` | yes |
| t14s (Fedora) | podman 5.x | Fedora Workstation itself (toolbox needs it); declared in `platform/fedora/packages` | **no** |

The decision (2026-09-19, after weighing Docker CE, podman and a split):
`docker` semantics everywhere they are needed, because the workloads are
dev workloads (compose files from other people's READMEs, Testcontainers,
agents that shell out to `docker`) and the Mac already has Docker Desktop.
Podman covers ~90% of that through its Docker-compatible socket; the last
10% (Ryuk wanting the real socket, a compose feature `podman-compose`
lacks, a BuildKit-only Dockerfile) shows up as an unplanned hour. On the
servers, where the containers actually run, that hour is not worth saving
100 MB of daemon. On the laptop the containers mostly run *elsewhere*
(spectre, over the tailnet), so podman stays until it gets in the way.

What podman on t14s is for today: toolbox, and the occasional `podman run`.
It is **not** wired up as a Docker stand-in (no `podman-docker`, no
`DOCKER_HOST`). If you need `docker` on t14s, pull one of the levers below
rather than improvising.

## The rule on a server

Docker publishes a container port with NAT rules that run before ufw
sees the packet, so `ufw status` says nothing about what a container
exposes. fleet's role closes that two ways: `daemon.json` binds every
published port to `127.0.0.1` unless the compose file names an address,
and a `DOCKER-USER` chain drops forwarded traffic that did not arrive over
`lo`, `tailscale0` or a bridge. So:

```yaml
ports:
  - "5173:5173"              # 127.0.0.1:5173 on the box; tailscale serve 5173 to reach it
  - "100.x.y.z:5173:5173"    # the tailnet directly; the address is the Tailscale IP
```

`tailscale serve` is the default (see [remote-dev.md](remote-dev.md));
the explicit address is for things that need to see the client's real
tailnet IP.

## Lever 1: drive spectre's Docker from t14s (no daemon on the laptop)

The cheapest way to get a `docker` command on t14s. Fedora's `docker-cli`
is the client only: no dockerd, no group, nothing running; podman is
untouched. A *context* points it at spectre over ssh, so `docker compose
up` in a checkout on t14s builds and runs on spectre. The source tree is
sent over as the build context; bind mounts refer to paths on spectre.

1. `platform/fedora/packages`: add `docker-cli` under the containers
   comment (the comment already says why no `podman-docker`; the two
   conflict, dnf will refuse the pair).
2. `just sync`.
3. Once, as yourself:
   ```sh
   docker context create spectre --docker host=ssh://spectre
   docker context use spectre
   docker info | grep -i 'server version'     # spectre's daemon answers
   ```
   `~/.docker/contexts` is per-user state, not the repository's; a
   `home/dev/docker.nix` that writes it is the tidy version if this turns
   out to be permanent.

Undo: remove the line, `sudo dnf remove docker-cli`.

## Lever 2: Docker on t14s itself

Fedora packages Docker as `moby-engine` (the daemon, `dockerd`), plus
`docker-cli`, `docker-compose` (the compose plugin) and `docker-buildx`.
Checked 2026-09-19 on F44: 29.7.2, built August 2026, i.e. current with
upstream; `moby-engine` requires `container-selinux`, so SELinux policy
is Fedora's own. Prefer this over Docker's `docker-ce` dnf repository:
same daemon, but rebuilt in Fedora's update stream against Fedora's
kernel and policy, and no repository to add in bootstrap. The package
metadata encodes what may coexist: `moby-engine` **Conflicts** with
`docker-ce` and `podman-docker`, and **not** with `podman`. Podman and
Docker keep separate binaries, image stores (`/var/lib/containers`,
`/var/lib/docker`), sockets and units; toolbox keeps working.

1. `platform/fedora/packages`, under the containers comment:
   ```
   moby-engine
   docker-cli
   docker-compose
   docker-buildx
   ```
   Keep `podman`. Still no `podman-docker`.
2. `platform/fedora/bootstrap.sh`, a new numbered step next to sshd:
   ```sh
   # ---- N. Docker -------------------------------------------------------
   # moby-engine installs dockerd but does not start it. The docker group
   # is root-equivalent (the socket can mount /); log out and in once.
   sudo systemctl enable --now docker
   sudo usermod -aG docker "$USER"
   ```
3. `just sync`, log out and in, `docker compose version`.
4. `docker context use default` if Lever 1 was in use.

What is different from the Ubuntu boxes:

- **daemon.json**: fleet's `roles/docker/defaults/main.yml` is the
  reference. On a laptop the loopback binding and `DOCKER-USER` chain are
  less pressing (Fedora Workstation's firewalld zone already drops inbound
  except ssh/mdns, and Docker ≥ 20.10 puts `docker0` in its own firewalld
  zone by itself), but the log rotation and `live-restore` are worth
  copying: `sudo install -m 0644 -d /etc/docker` and the same JSON.
- **SELinux**: bind mounts need `:z` (`-v ./src:/app:z`), exactly as with
  podman. Never `setenforce 0`.
- **doctor** sees `docker` group membership and the unit as nothing; it
  only checks the package list. Fine.

Undo: delete the four lines, `sudo dnf remove moby-engine docker-cli
docker-compose docker-buildx`, `sudo gpasswd -d "$USER" docker`.

## Lever 3: make podman answer as Docker (not recommended)

For completeness, since it is what Fedora's docs push. `podman-docker`
puts a `docker` shim on PATH and `systemctl --user enable --now
podman.socket` gives a Docker-API socket; `DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock`
makes Testcontainers and compose find it. It is the setup most likely to
produce "works on the Mac, not on t14s", and `podman-docker` conflicts
with every real Docker package, so it forecloses Levers 1 and 2 until
removed. Reach for it only if the goal is specifically rootless and
daemonless on the laptop.

## Ubuntu servers: what fleet does, in one screen

So this document is enough to reason about all three OSes. `fleet/ansible/roles/docker`:

- Docker's apt repository (deb822, keyring), packages `docker-ce
  docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`,
  Ubuntu's own `docker.io`/`containerd`/`runc` removed first.
- `daemon.json`: loopback binding for the default bridge (`ip`) *and* for
  compose's bridges (`default-network-opts`); `local` log driver, 10 MB × 3;
  `live-restore`.
- `docker-user-chain.service`, a oneshot `PartOf=docker.service`, fills
  `DOCKER-USER`.
- An apt.conf drop-in adds `origin=Docker` to unattended-upgrades;
  Ubuntu's default list would otherwise never patch docker-ce.
- `docker_users: [ag]`; explicit because the socket is root.
- Applied to inventory group `containers`; a droplet joins by being
  listed there. Not in cloud-init, so `daemon.json` changes never need a
  rebirth.

Environment's part on a server is `platform/debian/bootstrap.sh` step 3:
report whether `docker` is there, install nothing. The Docker CLI is
deliberately not in Home Manager on any machine: `~/.nix-profile/bin/docker`
would shadow the system client, mismatch the daemon, and not find the
compose plugin in `/usr/libexec/docker/cli-plugins`.
