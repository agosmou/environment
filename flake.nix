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
      # nativeBuildInputs on PATH. Those tools are NOT installed on the
      # machine: they exist for the check and are gone after (cached in
      # /nix/store, pointed at by nothing). That is why the checks give the
      # same answer on a fresh clone, on CI, and here, and why `which zizmor`
      # finds nothing. To run one of them by hand for a full report:
      # `nix run nixpkgs#zizmor -- <file>`. `touch $out` at the end just
      # tells Nix the check produced its (empty) result.

      # Why: a typo in a shell script would otherwise only show up when it
      # runs: for functions.sh that is the next terminal, for bootstrap that
      # is a fresh machine halfway through setup. shellcheck reads bash for
      # common mistakes; `zsh -n` parses the zsh files without running them;
      # zizmor checks the CI workflow for the mistakes that get repositories
      # compromised (an action pinned to a movable tag, a token with more
      # permissions than the job needs).
      scriptLint =
        testPkgs.runCommand "environment-script-lint"
          {
            nativeBuildInputs = [
              testPkgs.just
              testPkgs.shellcheck
              testPkgs.zizmor
              testPkgs.zsh
            ];
          }
          ''
            shellcheck \
              ${./bootstrap} \
              ${./scripts/doctor} \
              ${./scripts/inventory} \
              ${./platform/fedora/bootstrap.sh} \
              ${./platform/debian/bootstrap.sh} \
              ${./platform/darwin/bootstrap.sh} \
              ${./tests/bootstrap.sh} \
              ${./home/shell/functions.sh}
            zsh -n \
              ${./home/shell/functions.sh} \
              ${./home/shell/zsh-keybindings.zsh}
            just --justfile ${./justfile} --list >/dev/null
            # zizmor audits the GitHub Actions workflow: unpinned actions,
            # excessive token permissions, credential persistence.
            zizmor --offline --no-progress ${./.github/workflows/check.yml}
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
      # Why: building proves every package exists and links; it does not
      # prove a binary runs on this CPU and OS. This takes a target's built
      # generation and executes every command it installs with its version
      # flag, from an empty environment, like a fresh login would. A broken
      # dynamic library, a wrong-architecture binary, or a tool that crashes
      # on start fails here instead of on the machine. Each module declares
      # its own command (custom.smoke), so the list is whatever the target
      # actually installs.
      smokeTest =
        name: home:
        let
          pkgs = home.pkgs;
          # Every custom.smoke entry the target's modules registered, in name
          # order. Nothing is listed here: see the option in home/common.nix.
          commands = builtins.attrValues home.config.custom.smoke;
        in
        pkgs.runCommand "environment-smoke-${name}" { } ''
          export HOME="$TMPDIR"
          bin=${home.activationPackage}/home-path/bin
          ${pkgs.lib.concatMapStringsSep "\n" (
            c: ''"$bin"/${c} >/dev/null || { echo "FAILED: ${c}"; exit 1; }''
          ) commands}
          echo "ran ${toString (builtins.length commands)} commands"
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
      # One Home Manager configuration per target, named by the target. The
      # user on each machine is set inside the target file (home.username);
      # it is not the same everywhere (ag on Linux, agomez on the Mac).
      homeConfigurations = {
        "workstation-x86_64-linux" = workstationLinux;
        "workstation-aarch64-darwin" = workstationDarwin;
        "server-x86_64-linux" = serverX86Linux;
        "server-aarch64-linux" = serverArmLinux;
      };

      # `nix run .#home-manager` gives the home-manager CLI at the version
      # pinned in flake.lock. bootstrap uses this so a new machine activates
      # with the same home-manager the checks were run with.
      packages = forAllSystems (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      # Tools for EDITING this repository, as opposed to everything above,
      # which describes the machine. `nix develop` opens a subshell with
      # these on PATH without installing anything. Needed in two situations
      # only: a fresh clone before the first apply (`nix develop -c just
      # check`, since just is not installed yet), and CI. On an applied
      # machine, just is already on PATH and `just fmt` runs nixfmt itself.
      #   just        the command runner
      #   nixfmt      formats .nix files; not wanted on the normal PATH
      #   shellcheck  lints the scripts; Neovim has its own private copy
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.nixfmt
              pkgs.shellcheck
            ];
          };
        }
      );

      checks = {
        x86_64-linux = {
          neovim-lua = neovimLua;
          scripts = scriptLint;
          bootstrap = bootstrapTests;
          workstation = workstationLinux.activationPackage;
          server = serverX86Linux.activationPackage;
          smoke = smokeTest "workstation-x86_64-linux" workstationLinux;
        };
        aarch64-linux = {
          server = serverArmLinux.activationPackage;
          smoke = smokeTest "server-aarch64-linux" serverArmLinux;
        };
        aarch64-darwin = {
          workstation = workstationDarwin.activationPackage;
          smoke = smokeTest "workstation-aarch64-darwin" workstationDarwin;
        };
      };
    };
}
