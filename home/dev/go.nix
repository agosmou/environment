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
}
