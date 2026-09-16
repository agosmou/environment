# environment

One repository that produces the same working environment on every machine:
Neovim, tmux, the shell, the terminal, and the tools around them. Linux and
macOS.

## Why It Is Shaped This Way

The goal is to open any computer and get to work, and never lose a day to a
broken environment.

1. So the environment has to be **reproducible**. Nix and Home Manager do
   that: this repository *is* the environment. Activating it builds every
   package and config file from these files, and the same files give the same
   result on any machine.
2. Reproducible cuts both ways. A mistake here is reproduced everywhere: a
   typo in a shell function breaks every new terminal on every machine that
   activates it. So the repository needs a way to be **known good** before it
   is applied.
3. That is `nix flake check`. One command that builds the environment for
   every target and runs the small checks in `flake.nix` (shell script lint,
   Neovim Lua parse). Those checks catch what Nix alone cannot see: Nix will
   happily install a script with a syntax error, because to Nix it is just a
   file.
4. CI runs the same command on a clean clone, on one runner per CPU and OS
   (x86 Linux, ARM Linux, Apple Silicon), so "works on my machine but I
   forgot to commit a file" is caught, and the Mac and ARM configurations
   are built and their tools run before any real machine gets them.

The daily loop is therefore: **edit, check, apply.**

## New Machine

One command on a machine with nothing on it. Pick the line for the machine:

```bash
# Fedora workstation
curl -fsSL https://raw.githubusercontent.com/agosmou/environment/main/bootstrap | bash -s -- --target workstation

# Apple Silicon Mac
curl -fsSL https://raw.githubusercontent.com/agosmou/environment/main/bootstrap | bash -s -- --target workstation

# Linux server, x86 or ARM (a Pi)
curl -fsSL https://raw.githubusercontent.com/agosmou/environment/main/bootstrap | bash -s -- --target server
```

`workstation` and `server` resolve to the full target for the machine's CPU
and OS (`workstation-x86_64-linux`, `workstation-aarch64-darwin`,
`server-x86_64-linux`, `server-aarch64-linux`). The script installs Nix
(Fedora's own package on Fedora, the upstream nixos.org installer elsewhere),
clones this repository into `~/environment`, activates the target, and runs
the platform step for the OS.

Then three one-time steps that put your identity on the machine. They are
deliberately not in the repository, so it can be public.

1. **Log in to GitHub.** Opens a browser, stores a token in
   `~/.config/gh/hosts.yml`:

   ```bash
   gh auth login
   ```

2. **Tell git who you are.** Create this file with your name and email (the
   directory `local/` is gitignored):

   ```ini
   # ~/environment/local/gitconfig.local
   [user]
       name = Your Name
       email = you@example.com
   ```

3. **Fedora only: log out of GNOME and log back in.** The desktop session
   reads the Nix profile's paths at login, so until you do this, Nix-installed
   apps (Ghostty, RustDesk) are missing from the app grid and Super-search,
   even though they run from a terminal. Once, after the first bootstrap.

The platform step is the only part that needs root, and it is small:

| OS | Declared in | Applied by |
|---|---|---|
| Fedora | `platform/fedora/packages` (dnf), `platform/fedora/keyd/` | `platform/fedora/bootstrap.sh` |
| macOS | `platform/darwin/Brewfile` | `platform/darwin/bootstrap.sh` |

Everything else on a machine comes from Home Manager and needs no root.

## Layout

| Directory | Contents |
|---|---|
| `home/shell/` | bash, zsh, and one file per command-line tool |
| `home/git/`, `home/ssh/` | git, gh, ssh |
| `home/neovim/`, `home/tmux/`, `home/terminal/` | editor, multiplexer, Ghostty |
| `home/desktop/` | things that need a screen: GNOME settings, clipboard, remote desktop; workstation targets only |
| `home/ai/` | the coding agents: OpenCode, Claude Code, Codex, and the skills all three share (`skills/`) |
| `targets/` | one file per machine type, listing exactly which of the above it imports |
| `platform/` | the root-level layer per OS: dnf and Homebrew manifests, keyd, the scripts that apply them |

## Targets

| Target | Intended use |
|---|---|
| `workstation-x86_64-linux` | Fedora workstation |
| `workstation-aarch64-darwin` | Apple Silicon Mac |
| `server-x86_64-linux` | x86 Linux server |
| `server-aarch64-linux` | ARM Linux server |

Linux targets use bash; the Mac uses zsh. Both get the same aliases,
functions, prompt, and command-line tools from `home/shell/`, where every
tool is one file: `ls home/shell/` is the list of what is installed, and
removing a tool is deleting its file and its import line in `targets/`.

## Daily Loop

Editing a file under `home/` changes nothing on the machine by itself: the
repository is a description, and `apply` is what turns it into a new Home
Manager generation and points the home directory at it. So every change is:

```bash
# 1. edit something, e.g. add a package to home/shell/tools.nix
just check     # 2. does it build? lints, every target evaluates
just apply     # 3. make it real on this machine
```

The machine knows which target it is: the first bootstrap records it at
`~/.config/environment/target`, and every recipe reads that. Pass a target
explicitly only to work on another machine's configuration, e.g.
`just build server-aarch64-linux`.

To confirm the machine matches what the repository says (after an apply, or
on a machine you have not touched in a while):

```bash
just doctor
```

`just` alone lists every recipe.

## When Something Is Wrong

Every apply creates a new generation and keeps the old ones, so a bad
apply is undone by going back one:

```bash
just rollback        # activate the previous generation; nothing is rebuilt
just generations     # see them all, newest first
```

The repository is unchanged by a rollback. Fix the file, `just check`,
`just apply` again. See [docs/nix.md](docs/nix.md) for what a generation is.

## Updating Packages

Nothing changes version on its own: `flake.lock` pins the exact nixpkgs and
Home Manager commits. To move forward:

```bash
just update          # rewrite flake.lock to the newest commits
just check
just apply
# use the machine for a bit
git commit flake.lock -m "Update nixpkgs and home-manager"
```

If the update broke something: `just rollback`, `git checkout flake.lock`,
`just apply`. Do this from a clean working tree so `flake.lock` is the only
change.

## Before Committing

```bash
just fmt             # format every .nix file
just secrets         # scan for anything that looks like a token
just check
```

Before the first apply on a new clone, `just` is not installed yet; run
recipes through the development shell: `nix develop -c just check`.

## What Is On A Machine

Everything a target installs is declared in exactly three places, split by
who needs root:

| Owner | Declared in | Applied by |
|---|---|---|
| Home Manager | `home/**.nix` | `just apply` |
| dnf (Fedora) | `platform/fedora/packages` | `just bootstrap` |
| Homebrew (macOS) | `platform/darwin/Brewfile` | `just bootstrap` |

`just inventory` prints all of it, evaluated from the flake rather
than from a hand-kept list: Home Manager packages, every file Home Manager
places in the home directory, the root-level manifest for that OS, and the
repository tree. `just doctor` compares the running machine against
the same declarations and fails on drift in both directions: declared but
missing, or installed by hand but not declared. Doctor only reports; nothing
is removed automatically.

To add or remove a tool, edit one of the three places and re-run the
matching command. Home Manager removes what is no longer declared; dnf and
Homebrew do not, so doctor lists the leftovers until you remove them.

## Read Next

- [docs/nix.md](docs/nix.md): where Nix puts things, how generations and
  rollback work, and where the config files under `~/.config` come from.
- [docs/remote-access.md](docs/remote-access.md): SSH and RustDesk between
  the machines, including the one-time macOS permission setup.
