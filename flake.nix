{
  description = "Portable Home Manager environments for ag";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkHome =
        { system, modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          inherit modules;
        };

      workstationLinux = mkHome {
        system = "x86_64-linux";
        modules = [ ./targets/workstation-x86_64-linux/home.nix ];
      };
      workstationDarwin = mkHome {
        system = "aarch64-darwin";
        modules = [ ./targets/workstation-aarch64-darwin/home.nix ];
      };
      serverX86Linux = mkHome {
        system = "x86_64-linux";
        modules = [ ./targets/server-x86_64-linux/home.nix ];
      };
      serverArmLinux = mkHome {
        system = "aarch64-linux";
        modules = [ ./targets/server-aarch64-linux/home.nix ];
      };

      testPkgs = pkgsFor "x86_64-linux";

      # ---- Checks ----------------------------------------------------------
      # A check is a small test that `nix flake check` runs. If any check
      # fails, the command fails. They exist so a mistake in this repository
      # is caught by running one command, before it is applied to a machine
      # where it would break the shell or the editor.
      #
      # Each check runs in a sandbox with only the tools listed under
      # nativeBuildInputs, so it gives the same answer on every machine and
      # in CI. `touch $out` at the end just tells Nix the check produced its
      # (empty) result.

      # Why: a typo in a shell script would otherwise only show up when it
      # runs: for functions.sh that is the next terminal, for bootstrap that
      # is a fresh machine halfway through setup. shellcheck reads bash for
      # common mistakes; `zsh -n` parses the zsh files without running them.
      scriptLint =
        testPkgs.runCommand "environment-script-lint"
          {
            nativeBuildInputs = [
              testPkgs.shellcheck
              testPkgs.zsh
            ];
          }
          ''
            shellcheck \
              ${./bootstrap} \
              ${./platform/fedora/bootstrap.sh} \
              ${./platform/darwin/bootstrap.sh} \
              ${./tests/bootstrap.sh} \
              ${./home/shell/functions.sh}
            zsh -n \
              ${./home/shell/functions.sh} \
              ${./home/shell/zsh-keybindings.zsh}
            touch $out
          '';

      # Why: bootstrap decides which target a machine gets from `uname`. If
      # that logic breaks, a new machine gets the wrong configuration or
      # none. tests/bootstrap.sh runs the --dry-run path for every supported
      # machine and several unsupported ones.
      bootstrapTests = testPkgs.runCommand "environment-bootstrap-tests" { } ''
        BOOTSTRAP=${./bootstrap} ${testPkgs.bash}/bin/bash ${./tests/bootstrap.sh}
        touch $out
      '';
      # Why: a Lua syntax error in the Neovim config would otherwise only
      # show up when Neovim starts. This parses every Lua file without
      # running it and fails on the first one that does not parse.
      neovimLua =
        testPkgs.runCommand "environment-neovim-lua" { nativeBuildInputs = [ testPkgs.neovim ]; }
          ''
            nvim --clean --headless -u NONE -i NONE \
              '+lua local root="${./home/neovim/config}"; local files=vim.fn.glob(root.."/**/*.lua",false,true); if #files==0 then vim.api.nvim_err_writeln("no Lua files found"); vim.cmd.cquit() end; for _,f in ipairs(files) do local chunk,err=loadfile(f); if not chunk then vim.api.nvim_err_writeln(f..": "..tostring(err)); vim.cmd.cquit() end end' \
              +qa
            touch $out
          '';
    in
    {
      homeConfigurations = {
        "ag@workstation-x86_64-linux" = workstationLinux;
        "ag@workstation-aarch64-darwin" = workstationDarwin;
        "ag@server-x86_64-linux" = serverX86Linux;
        "ag@server-aarch64-linux" = serverArmLinux;
      };

      # `nix run .#home-manager` gives the home-manager CLI at the version
      # pinned in flake.lock. bootstrap uses this so a new machine activates
      # with the same home-manager the checks were run with.
      packages = forAllSystems (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      checks = {
        x86_64-linux = {
          neovim-lua = neovimLua;
          scripts = scriptLint;
          bootstrap = bootstrapTests;
          workstation = workstationLinux.activationPackage;
          server = serverX86Linux.activationPackage;
        };
        aarch64-linux.server = serverArmLinux.activationPackage;
        aarch64-darwin.workstation = workstationDarwin.activationPackage;
      };
    };
}
