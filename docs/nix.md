# Nix In Five Minutes

Everything Nix installs lives in one place, `/nix/store`. Nothing is written
to `/usr/bin`, `/usr/lib`, or `~/.local/bin`. Each package is one immutable
directory named by a hash of everything that went into building it:

```text
/nix/store/3micl37dibw3kjiv5k101yw92w6h7amh-neovim-0.12.5/bin/nvim
           └──────────── hash ─────────────┘ └── name ───┘
```

What makes those packages usable is a chain of symlinks from the home
directory into the store. Following `nvim` from the shell to the binary:

```text
$ which nvim
~/.nix-profile/bin/nvim
    │
    │  ~/.nix-profile  ->  ~/.local/state/nix/profiles/profile
    │  ~/.local/state/nix/profiles/home-manager  ->  home-manager-N-link
    │                                                 (generation N, current)
    ▼
/nix/store/...-home-manager-generation/
    ├── home-path/bin/    every command this environment provides, each a
    │                     symlink to its package
    ├── home-files/       the targets of the ~/.config symlinks
    └── activate          the script that `just apply` runs
    │
    ▼
/nix/store/...-neovim-0.12.5/bin/nvim
```

Three layers, each answering a different question:

| Layer | Path | What it is |
|---|---|---|
| Store | `/nix/store/<hash>-<name>/` | Every package ever built or downloaded, including old versions and build-only dependencies. Only grows until garbage collected. |
| Generation | `~/.local/state/nix/profiles/home-manager-N-link` | One snapshot of this environment: symlinks to exactly the packages and files the modules declared at that switch. Old generations stay, which is what makes rollback instant. |
| PATH | `~/.nix-profile/bin` | The one directory the shell searches. Points at the current generation. |

An apply builds a new generation and repoints the symlinks. It never edits a
file in place, so a failed build leaves the current generation untouched.

```bash
# Build and activate a new generation from this repository (`just apply`).
# Home Manager's own word for it is "switch", as in switch generations.
nix run home-manager -- switch --flake .#ag@workstation-x86_64-linux

# Every generation, newest last; roll back by activating an older one
nix run home-manager -- generations

# What is on PATH right now
ls ~/.nix-profile/bin

# Everything the current generation depends on, transitively
nix path-info -r ~/.local/state/nix/profiles/home-manager | wc -l

# The same list with sizes, largest last
nix path-info -rSh ~/.local/state/nix/profiles/home-manager | sort -k2 -h | tail

# What garbage collection would delete (nothing is deleted by this)
nix-store --gc --print-dead | wc -l

# Delete old generations and every store path nothing references
nix-collect-garbage -d
```

Nix does not touch mutable state: Neovim's plugin data in
`~/.local/share/nvim`, tmux session snapshots, shell history. Those are runtime
files, not configuration, and they are not in this repository.

## Flakes And nix.conf

**nix.conf** is Nix's own settings file
([reference](https://nix.dev/manual/nix/latest/command-ref/conf-file)). Two
copies matter: `/etc/nix/nix.conf` for everyone on the machine, and
`~/.config/nix/nix.conf` for one user. Nix also reads the `NIX_CONFIG`
environment variable as if it were extra lines of that file, which is how a
single command can be given a setting without touching either file.

**A flake** is a repository with a `flake.nix` at its root that declares its
inputs (here: nixpkgs and Home Manager, at exact commits recorded in
`flake.lock`) and its outputs (here: the four targets, the checks, the
formatter). Before flakes, a Nix config depended on whatever version of
nixpkgs the machine's "channel" happened to be at, which is how two machines
running the same config ended up different. A flake takes its inputs from the
lock file and nothing else. That is what makes `just apply` give the same
result on every machine, and why this repository is one.

Flakes, and the `nix <verb>` command line that goes with them (`nix build`,
`nix run`, `nix flake check`), are still marked **experimental** in Nix and
are off by default. In practice every Nix user turns them on and has for
years; "experimental" here means the interface is not yet frozen, not that
it is unreliable. Off, every command in this repository fails with
`experimental feature 'nix-command' is disabled`
([the setting](https://nix.dev/manual/nix/latest/command-ref/conf-file#conf-experimental-features),
[what each feature is](https://nix.dev/manual/nix/latest/development/experimental-features)).

They are turned on the same way on every machine: one line in
`/etc/nix/nix.conf`, system-wide, so every user and every nix process sees
it. Fedora's Nix package ships that line; on macOS and Ubuntu the upstream
installer does not, so `bootstrap` appends it right after installing Nix.
`just doctor` checks it is in effect. The per-user file
`~/.config/nix/nix.conf` is not used.

## Where Config Files Come From

Home Manager writes the files under `~/.config` as symlinks into the Nix
store; the files on disk are build output, not source. To change one, edit
its module under `home/` and run `just apply` again. Editing the symlink target
fails because the store is read-only.

Two styles are in use, and both are legitimate:

- **Generated from Nix attributes.** Ghostty, tmux, and starship are declared
  as `settings = { ... }` blocks and rendered to their native formats. No
  config file exists in this repository for them.
- **Real files.** Neovim's Lua lives as source in `home/neovim/config/` and is
  linked in unchanged. That is not a Nix-generated config.

If a generated config would be easier to tweak as plain text, switch it to a
real file. For Ghostty that is `xdg.configFile."ghostty/config".source =
./config;` in `home/terminal/ghostty.nix` with the file beside it. Nix
attributes are simply what this repository chose for the small configs.
