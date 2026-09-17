# Projects

How language tools are managed, and how a project gets its own.

## Two layers

```
inside a project directory with a flake:   the project's tools     (nix develop / direnv)
everywhere:                                the global tools        (home/dev/, via just sync)
underneath:                                the OS
```

The **global layer** is `home/dev/`, one file per tool, on every target:

| Tool | Gives you | Versions live in |
|---|---|---|
| uv | Python: `uv init`, `uv add`, `uv run`, `uv python install 3.13` | `~/.local/share/uv/`, per-project `.venv` |
| go, gopls | `go build/run/test`, the language server | one global version |
| bun | JS/TS runtime and package manager | one global version |
| rustup, cargo-nextest | `cargo`, `rustc`, `clippy`, `rustfmt`; `cargo nextest run` | `~/.rustup/`, per toolchain |

Python type checking is pyrefly, inside Neovim and as `pyrefly check`. With
no config it runs a lenient preset (so untyped code is not a wall of errors);
a project turns on full checking with two lines in `pyproject.toml`:

```toml
[tool.pyrefly]
preset = "default"   # or "strict"
```

Two of these (uv, rustup) are *managers*: the global thing is the tool, and
the versions it installs are runtime state on the machine, controlled per
project by `.python-version` / `pyproject.toml` and `rust-toolchain.toml`.
The other two are one version each; a project that needs a different one
pins it in its flake (below).

Once per machine, after the first apply: `rustup default stable`. `doctor`
reminds you until it is done.

The **project layer** is a `flake.nix` in the repository. Entering the
directory puts that flake's tools first on PATH; leaving restores the global
ones. Nothing to switch by hand.

## Entering a project

`direnv` (`home/shell/direnv.nix`) does it on `cd`. A project needs a
`.envrc` next to its `flake.nix`:

```bash
use flake
```

The first time in a new directory, direnv refuses until you approve the file:

```bash
direnv allow
```

Then every `cd` in loads the shell (cached by nix-direnv, so it is instant
after the first time) and every `cd` out unloads it. Without direnv,
`nix develop` opens the same shell explicitly.

## Starting a project

Copy this `flake.nix` into the new repository and keep the tools the project
needs:

```nix
{
  description = "my-project";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # One dev shell per system this project is built on.
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              # Pick what this project needs. Anything listed here is the
              # project's version inside this directory, whatever is global.
              pkgs.go # a specific Go: pkgs.go_1_24
              pkgs.bun
              pkgs.uv # Python itself comes from uv: `uv python install`
              pkgs.rustup # or a fixed toolchain: pkgs.cargo pkgs.rustc
              pkgs.just
            ];
          };
        }
      );
    };
}
```

Then:

```bash
echo 'use flake' > .envrc
direnv allow
git add flake.nix .envrc
nix flake lock          # writes flake.lock; commit it, it pins the versions
```

`flake.lock` is what makes the project's tools the same on every machine and
for everyone who clones it, exactly as this repository's own lock does for the
environment.

## Entering someone else's project

If it has a `flake.nix`: `direnv allow` (or `nix develop`) and its tools are
in place; the global ones are untouched. If it does not, the global tools
serve, and `uv`/`rustup` still honour any `.python-version` or
`rust-toolchain.toml` the project carries.
