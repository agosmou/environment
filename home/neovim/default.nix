{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Interpreter that hosts the debugpy adapter for nvim-dap-python. The wrapper
  # only suffixes extraPackages onto PATH, so the exact path is handed to Lua
  # through NVIM_DEBUGPY_PYTHON instead of relying on `python3` resolution.
  debugPython = pkgs.python3.withPackages (ps: [ ps.debugpy ]);
in
{
  custom.smoke.nvim = "nvim --version";

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # The config disables every remote-plugin provider (custom/options.lua):
    # all plugins are Lua, and LSPs and debuggers run as their own binaries.
    # Options:
    #   true   bundle a Node.js / Python interpreter for provider-based plugins
    #   false  none; saves about 250 MiB (Node) and the provider warnings
    withNodeJs = false;
    withPython3 = false;
    extraWrapperArgs = [
      "--set"
      "NVIM_DEBUGPY_PYTHON"
      "${debugPython}/bin/python"
    ];
    extraPackages = [
      pkgs.black
      pkgs.curl
      pkgs.delve
      pkgs.diffutils
      pkgs.gnumake
      pkgs.gnutar
      pkgs.gzip
      pkgs.lua-language-server
      pkgs.markdownlint-cli2
      pkgs.pyright
      debugPython
      pkgs.ruff
      pkgs.rust-analyzer
      pkgs.shfmt
      pkgs.shellcheck
      pkgs.stdenv.cc
      pkgs.stylua
      pkgs.tree-sitter
      pkgs.unzip
      pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter
    ];
  };

  # Recursive mode creates per-file links, leaving ~/.config/nvim writable for
  # vim.pack's lockfile while the reviewed Lua sources remain immutable.
  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };

  # vim.pack rewrites its lock during normal startup. Seed a regular writable
  # copy from the reviewed repository lock after Home Manager links the config.
  home.activation.installNeovimPackLock = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run install -m 0644 ${./nvim-pack-lock.json} \
      ${config.xdg.configHome}/nvim/nvim-pack-lock.json
  '';
}
