# uv: Python project and version manager. `uv init`, `uv add`, `uv run`,
# and `uv python install 3.13` for interpreters.
#
# This is the only Python-related thing installed globally. uv downloads
# interpreters into ~/.local/share/uv/ and makes a venv per project; both are
# runtime state, not Nix's. A project pins its version in .python-version or
# pyproject.toml, so the interpreter is project-controlled even though the uv
# binary is global. See docs/projects.md.
#
# Plain package: nothing to configure.
{ pkgs, ... }:

{
  home.packages = [ pkgs.uv ];
  custom.smoke.uv = "uv --version";
}
