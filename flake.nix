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

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      checks = {
        x86_64-linux = {
          neovim-lua = neovimLua;
          workstation = workstationLinux.activationPackage;
          server = serverX86Linux.activationPackage;
        };
        aarch64-linux.server = serverArmLinux.activationPackage;
        aarch64-darwin.workstation = workstationDarwin.activationPackage;
      };
    };
}
