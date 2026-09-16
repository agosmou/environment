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
4. Later, CI runs the same command on a clean clone, so "works on my machine
   but I forgot to commit a file" is caught too.

The daily loop is therefore: **edit, check, switch.**

## Targets

| Target | Intended use |
|---|---|
| `workstation-x86_64-linux` | Fedora workstation |
| `workstation-aarch64-darwin` | Apple Silicon Mac |
| `server-x86_64-linux` | x86 Linux server |
| `server-aarch64-linux` | ARM Linux server |

## Commands

```bash
# Check: every target evaluates, the native ones build, the lints pass
nix flake check --all-systems --no-build
nix flake check

# Switch: build and activate a target on this machine
nix run home-manager -- switch --flake .#ag@workstation-x86_64-linux
```

## Read Next

- [docs/nix.md](docs/nix.md): where Nix puts things, how generations and
  rollback work, and where the config files under `~/.config` come from.
