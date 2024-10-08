# SPDX-FileCopyrightText: 2024 SoupGlasses <sofi+git@mailbox.org>
#
# SPDX-License-Identifier: MIT
{
  description = "Run graphics accelerated programs built with Nix on any Linux distribution";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
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
    # Holds re-usable system modules meant for systemConfigs to include.

    systemModules = {
      default = self.systemModules.graphics;
      graphics = import ./system/modules/graphics.nix;
    };

    # -- System Configurations --
    # Holds Nix system configurations for Linux computers.

    systemConfigs = let
      # Use fetchTarball to import system-manager within the example
      # systemConfigs to prevent dependants from needing to override it if it
      # instead was imported as a flake input.
      system-manager = builtins.fetchTarball {
        url = "https://github.com/soupglasses/system-manager-lite/archive/40ec3633e4cf41fa01dbf144cec0b18e03810197.tar.gz";
        sha256 = "0gkd1sjffll9il9w3vvyk6ypra6i8x1cvx7wbhy352s3xbp233nm";
      };
      system-manager-lib = import "${system-manager}/nix/lib.nix" {inherit nixpkgs;};
    in {
      default = system-manager-lib.makeSystemConfig {
        modules = [
          self.systemModules.default
          ({...}: {
            config = {
              nixpkgs.hostPlatform = "x86_64-linux";
              system-manager.allowAnyDistro = true;
              system-graphics.enable = true;
            };
          })
        ];
      };
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
          reuse
        ];
      };
    });
  };
}
