# Skills for the coding agents: one list, given to all three tools.
#
# A skill is a directory with a SKILL.md (name and description up top,
# instructions below) and optionally other files. Each agent reads skills
# from its own directory; this module symlinks every skill here into all
# three, so one folder in the repository means every agent on every machine
# has it:
#
#   ~/.claude/skills/<name>            Claude Code
#   ~/.codex/skills/<name>             Codex
#   ~/.config/opencode/skills/<name>   OpenCode
#
# Two kinds of skill:
#   own       written here, under home/ai/skills/<name>/
#   vendored  someone else's, fetched from GitHub at a pinned commit. The
#             text never enters this repository; Nix fetches it and the hash
#             guarantees it is the reviewed version. To update: change rev,
#             clear the hash, run `just check`, paste the hash Nix reports.
#
# No separate skills manager (slinky, npx skills) is needed: they exist to do
# this symlinking for people without Home Manager.
{ pkgs, ... }:

let
  # https://github.com/humanlayer/skills (MIT)
  humanlayer = pkgs.fetchFromGitHub {
    owner = "humanlayer";
    repo = "skills";
    rev = "3c2629142c5d437428269b1b722b08c0b87f574d";
    hash = "sha256-lJvu9CGAN/+dzmzck0CodRXn/p7GUkCbfyZxys4nIoU=";
  };

  # https://github.com/mattpocock/skills (MIT)
  mattpocock = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "959a8e9f1edc3adbe2f7e3054bb6fbefa6696260";
    hash = "sha256-AbIlPEE0VWJq+NJpa56SDzhM8o7vXDBtlJHS5FCTElE=";
  };

  skills = {
    # Own. PR descriptions with a TL;DR note, diagrams, a shaped diff, the
    # alternatives, and reading order for the reviewer.
    pr-description = ./skills/pr-description;

    # Explain the current topic visually: pseudocode, call trees, file
    # trees, Mermaid, diffs. Invoke with "show me".
    show-me = "${humanlayer}/plugins/show-me/skills/show-me";

    # Relentless interview to stress-test a plan, round by round, plus a
    # glossary (CONTEXT.md) and ADRs written as decisions land. It is a
    # two-line composite that invokes the next two, so all three are needed.
    grill-with-docs = "${mattpocock}/skills/engineering/grill-with-docs";
    grilling = "${mattpocock}/skills/productivity/grilling";
    domain-modeling = "${mattpocock}/skills/engineering/domain-modeling";
  };
in
{
  programs.claude-code.skills = skills;
  programs.codex.skills = skills;
  programs.opencode.skills = skills;
}
