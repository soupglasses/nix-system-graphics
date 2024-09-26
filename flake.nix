{
  description = "Run graphics accelerated programs built with Nix on any Linux distribution";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.system-manager.url = "github:numtide/system-manager";
  inputs.system-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    system-manager,
  }: let
    systems = ["aarch64-linux" "x86_64-linux"];
    eachSystem = f:
      nixpkgs.lib.genAttrs systems (system:
        f {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        });
  in {
    # -- System Modules --
    #

    systemModules = {
      default = self.systemModules.opengl;
      opengl = import ./system/modules/opengl.nix;
    };

    # -- System Configurations --
    #

    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        self.systemModules.default
        ({...}: {
          config = {
            nixpkgs.hostPlatform = "x86_64-linux";
            system-manager.allowAnyDistro = true;
            system-opengl.enable = true;
          };
        })
      ];
    };

    # -- Development Shells --
    # Scoped environments including packages and shell-hooks to aid project development.

    devShells = eachSystem ({pkgs, ...}: {
      default = pkgs.mkShellNoCC {
        shellHook = ''
          ${pkgs.pre-commit}/bin/pre-commit install --install-hooks --overwrite
        '';
        nativeBuildInputs = with pkgs; [
          pre-commit
          alejandra
          deadnix
          editorconfig-checker
        ];
      };
    });
  };
}
