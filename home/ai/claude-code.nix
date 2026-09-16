# Claude Code: Anthropic's terminal coding agent. `claude` in a project
# directory.
#
# Home Manager module: installs the binary. ~/.claude/settings.json is left
# on the machine on purpose: Claude Code writes permission grants into it
# ("always allow"), which fails if it is a read-only managed file. The
# module can manage `settings`, `agents`, `commands`, `hooks`, `mcpServers`,
# and `skills` from the repository; add those here when they exist. Skills
# would live under home/ai/skills/ and be declared with `skills`, so no
# separate skills manager is needed.
{ ... }:

{
  programs.claude-code.enable = true;
}
