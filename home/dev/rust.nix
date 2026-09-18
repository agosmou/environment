# Rust, through rustup. rustup is the installer: it downloads toolchains
# (each one is rustc + cargo + rustfmt + clippy + std) into ~/.rustup and
# puts proxy commands named `cargo`, `rustc`, and so on on PATH that run the
# toolchain a project selects. So one global rustup gives every version of
# Rust, the same way uv does for Python. Once per machine, after the first
# apply:
#
#   rustup default stable
#
# doctor reminds you until that is done. A project pins its version in a
# rust-toolchain.toml and rustup obeys it. See docs/projects.md.
#
# In short: rustup installs Rust; cargo is Rust's build tool and package
# manager and is what you use for everything after that. `rustup default
# stable` is the one command that has to come first, because cargo is part
# of the toolchain it downloads.
#
# cargo-nextest: a faster `cargo test` runner (`cargo nextest run`); a plain
# binary that cargo finds as a subcommand. Rust tools like this are usually
# installed with `cargo install`, which compiles them into ~/.cargo/bin,
# unpinned and invisible to this repository. From nixpkgs instead, they are
# declared here, pinned by flake.lock, and smoke-tested like everything else.
#
# rust-analyzer, the language server, comes from nixpkgs via
# home/neovim/default.nix rather than from rustup, so Neovim has it before
# any toolchain is installed.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.rustup
    pkgs.cargo-nextest
  ];
  custom.smoke = {
    rustup = "rustup --version";
    cargo-nextest = "cargo-nextest nextest --version";
  };
}
