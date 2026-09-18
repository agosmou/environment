# Go toolchain: `go build`, `go run`, `go test`, and the `gopls` language
# server Neovim uses. One global version for scripts and quick programs; a
# project that needs a specific version pins it in its own flake, which wins
# inside that directory. See docs/projects.md.
#
# Plain package. GOPATH defaults to ~/go, runtime state.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.go
    pkgs.gopls
  ];
  custom.smoke = {
    go = "go version";
    gopls = "gopls version";
  };
  # gopls is also Neovim's Go language server, so it is registered here for
  # doctor's Neovim check (custom.neovimTools). It is declared in THIS file
  # rather than in home/neovim/default.nix because it is installed with the
  # Go toolchain, on the shell PATH (it is a command-line tool too: `gopls
  # check`), and Neovim inherits the shell PATH. The Neovim module's own
  # extraPackages are the tools that exist only for Neovim, on its private
  # PATH. Both declarations land in the same list; Nix merges them.
  custom.neovimTools = [ "gopls" ];
}
