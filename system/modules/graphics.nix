# SPDX-FileCopyrightText: 2003-2024 Eelco Dolstra and the Nixpkgs/NixOS contributors
# SPDX-FileCopyrightText: 2024 SoupGlasses <sofi+git@mailbox.org>
#
# SPDX-License-Identifier: MIT
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;

  cfg = config.system-graphics;

  driversEnv = pkgs.buildEnv {
    name = "graphics-drivers";
    paths = [cfg.package] ++ cfg.extraPackages;
  };

  driversEnv32 = pkgs.buildEnv {
    name = "graphics-drivers-32bit";
    paths = [cfg.package32] ++ cfg.extraPackages32;
  };
in {
  options = {
    system-graphics = {
      enable = lib.mkOption {
        description = ''
          Whether to enable hardware accelerated graphics drivers.

          This is required to allow most graphical applications and
          environments to use hardware rendering, video encode/decode
          acceleration, etc.
        '';
        type = types.bool;
        default = false;
      };

      enable32Bit = lib.mkOption {
        description = ''
          On 64-bit systems, whether to also install 32-bit drivers for
          32-bit applications (such as Wine).
        '';
        type = lib.types.bool;
        default = false;
      };

      package = lib.mkPackageOption pkgs ["mesa" "drivers"] {};

      package32 = lib.mkPackageOption pkgs ["pkgsi686Linux" "mesa" "drivers"] {
        extraDescription = ''
          Used when {option}`enable32Bit` is enabled.
        '';
      };

      extraPackages = lib.mkOption {
        description = ''
          Additional packages to add to OpenGL drivers.
          This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.

          ::: {.note}
          intel-media-driver supports hardware Broadwell (2014) or newer. Older hardware should use the mostly unmaintained intel-vaapi-driver driver.
          :::
        '';
        type = types.listOf types.package;
        default = [];
        example = lib.literalExpression "with pkgs; [ intel-media-driver intel-ocl intel-vaapi-driver ]";
      };

      extraPackages32 = lib.mkOption {
        description = ''
          Additional packages to add to 32-bit OpenGL drivers on 64-bit systems.
          Used when {option}`driSupport32Bit` is set. This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.

          ::: {.note}
          intel-media-driver supports hardware Broadwell (2014) or newer. Older hardware should use the mostly unmaintained intel-vaapi-driver driver.
          :::
        '';
        type = types.listOf types.package;
        default = [];
        example = lib.literalExpression "with pkgs.pkgsi686Linux; [ intel-media-driver intel-vaapi-driver ]";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enable32Bit -> pkgs.stdenv.isx86_64;
        message = "Option `system-graphics.enable32Bit` only makes sense on a 64-bit system.";
      }
    ];

    systemd.tmpfiles.rules = [
      "L+ /run/opengl-driver - - - - ${driversEnv}"
      (
        if pkgs.stdenv.isi686
        then "L+ /run/opengl-driver-32 - - - - opengl-driver"
        else if cfg.enable32Bit
        then "L+ /run/opengl-driver-32 - - - - ${driversEnv32}"
        else "r /run/opengl-driver-32"
      )
    ];

    system-manager.preActivationAssertions.systemGraphicsEnsureNoNixOS = {
      enable = true;
      script = ''
        source /etc/os-release
        if [ $ID = "nixos" ]; then
          echo "You cannot run nix-system-graphics on a NixOS system."
          echo "Please use the 'hardware.graphics' module in NixOS instead."
          exit 1
        fi
      '';
    };
  };
}
