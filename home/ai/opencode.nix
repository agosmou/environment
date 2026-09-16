# OpenCode: terminal AI coding agent, the primary one. `opencode` in a
# project directory.
#
# Home Manager module: installs the binary. Its settings
# (~/.config/opencode/opencode.jsonc), auth, and sessions are left on the
# machine: the tool writes to them itself and a managed copy would be
# read-only. The module can manage `settings`, `agents`, `commands`, and
# `skills` from the repository when there is something worth sharing across
# machines; until then nothing is declared.
{ ... }:

{
  programs.opencode.enable = true;
  custom.smoke.opencode = "opencode --version";
}
