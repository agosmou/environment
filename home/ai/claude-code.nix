# Claude Code: Anthropic's terminal coding agent. `claude` in a project
# directory.
#
# Home Manager module: installs the binary. ~/.claude/settings.json is left
# on the machine on purpose: Claude Code writes permission grants into it
# ("always allow"), which fails if it is a read-only managed file. The
# module can manage `settings`, `agents`, `commands`, `hooks`, and
# `mcpServers` from the repository; add those here when they exist. Skills
# are already managed: see home/ai/skills/.
{ ... }:

{
  programs.claude-code.enable = true;
  custom.smoke.claude = "claude --version";
}
