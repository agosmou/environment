{ ... }:

{
  programs.starship = {
    enable = true;
    settings.aws.style = "#c76926";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
