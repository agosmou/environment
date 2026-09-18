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

  # Executables the config expects. Kept next to extraPackages below, which
  # provide them; doctor verifies each is reachable from inside Neovim.
  # Package names and executable names differ (delve -> dlv, stdenv.cc -> cc,
  # vscode-langservers-extracted -> several), which is why this is a list of
  # executables and not derived from the packages.
  #
  # Not every tool Neovim uses is listed here: a tool that is installed for
  # the shell as well (gopls, with the Go toolchain in home/dev/go.nix) is
  # registered in its own module, and Nix merges the lists. This list is the
  # tools that exist only for Neovim, on its private PATH.
  custom.neovimTools = [
    # basics the config and plugins shell out to
    "git"
    "curl"
    "tar"
    "gzip"
    "unzip"
    "rg"
    "fd"
    "lazygit"
    # tree-sitter builds syntax parsers with a C compiler
    "tree-sitter"
    "cc"
    # language servers
    "pyrefly"
    "lua-language-server"
    "rust-analyzer"
    "typescript-language-server"
    "vscode-eslint-language-server"
    # formatters and linters
    "stylua"
    "ruff"
    "prettier"
    "biome"
    "markdownlint-cli2"
    "shellcheck"
    "shfmt"
    # debug adapters
    "dlv"
  ];

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
      pkgs.curl
      pkgs.delve
      pkgs.diffutils
      pkgs.gnumake
      pkgs.gnutar
      pkgs.gzip
      pkgs.lua-language-server
      pkgs.markdownlint-cli2
      pkgs.pyrefly # Python language server and type checker
      # JavaScript/TypeScript. The language server, plus HTML/CSS/JSON/ESLint
      # servers; prettier as the fallback formatter and biome for projects that
      # use it. Linting comes from the project (eslint or biome config).
      pkgs.typescript-language-server
      pkgs.vscode-langservers-extracted
      pkgs.prettier
      pkgs.biome
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
