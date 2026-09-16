# starship: the prompt. Shows directory, git branch and status, language
# versions when inside a project, and command duration.
#
# Home Manager module: installs the binary, writes ~/.config/starship.toml
# from `settings`, and adds the prompt hook to ~/.bashrc and ~/.zshrc.
{ ... }:

{
  programs.starship = {
    enable = true;
    # Colour of the AWS profile segment, shown when AWS_PROFILE is set.
    settings.aws.style = "#c76926";
  };
}
