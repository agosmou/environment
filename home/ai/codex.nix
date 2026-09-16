# Codex: OpenAI's terminal coding agent. `codex` in a project directory.
#
# Home Manager module: installs the binary. ~/.codex (config, auth,
# sessions) is left on the machine for the same reason as the other two:
# the tool writes to it. `settings`, `profiles`, and `skills` can be managed
# here later.
{ ... }:

{
  programs.codex.enable = true;
}
