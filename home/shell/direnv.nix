# direnv: runs a project's environment when you cd into it and unloads it
# when you leave. With a `.envrc` containing `use flake`, entering a
# directory that has a flake.nix puts that project's tools first on PATH
# (its Go, its Python, its exact versions) and leaving restores the global
# ones. This is how a project's flake "wins" over the tools installed here.
# See docs/projects.md.
#
# Home Manager module: installs direnv and adds its hook to ~/.bashrc and
# ~/.zshrc.
{ ... }:

{
  programs.direnv = {
    enable = true;
    # nix-direnv caches the flake's shell so re-entering a directory is
    # instant instead of re-evaluating the flake every time.
    # Options:
    #   true   cache (nix-direnv)
    #   false  plain direnv; `use flake` re-evaluates on every cd
    nix-direnv.enable = true;
    # Options:
    #   true   no "direnv: loading ..." lines when entering a directory
    #   false  print what direnv loads and unloads
    silent = false;
  };
  custom.smoke.direnv = "direnv --version";
}
