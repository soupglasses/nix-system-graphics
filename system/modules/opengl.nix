# Copyright (c) 2003-2024 Eelco Dolstra and the Nixpkgs/NixOS contributors
# Copyright (c) 2024 SoupGlasses
# See LICENSE file for license terms.
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;

  cfg = config.system-opengl;

  package = pkgs.buildEnv {
    name = "opengl-drivers";
    paths = [cfg.package] ++ cfg.extraPackages;
  };

  package32 = pkgs.buildEnv {
    name = "opengl-drivers-32bit";
    paths = [cfg.package32] ++ cfg.extraPackages32;
  };
in {
  options = {
    system-opengl = {
      enable = lib.mkOption {
        description = ''
          Whether to enable OpenGL drivers. This is needed to enable
          OpenGL support in X11 systems, as well as for Wayland compositors
          like sway and Weston.
        '';
        type = types.bool;
        default = false;
      };

      driSupport = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable accelerated OpenGL rendering through the
          Direct Rendering Interface (DRI).
        '';
      };

      driSupport32Bit = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          On 64-bit systems, whether to support Direct Rendering for
          32-bit applications (such as Wine).  This is currently only
          supported for the `nvidia` as well as
          `Mesa`.
        '';
      };

      package = lib.mkOption {
        type = types.package;
        internal = true;
        description = ''
          The package that provides the OpenGL implementation.
        '';
      };

      package32 = lib.mkOption {
        type = types.package;
        internal = true;
        description = ''
          The package that provides the 32-bit OpenGL implementation on
          64-bit systems. Used when {option}`driSupport32Bit` is
          set.
        '';
      };

      extraPackages = lib.mkOption {
        type = types.listOf types.package;
        default = [];
        example = lib.literalExpression "with pkgs; [ intel-media-driver intel-ocl intel-vaapi-driver ]";
        description = ''
          Additional packages to add to OpenGL drivers.
          This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.

          ::: {.note}
          intel-media-driver supports hardware Broadwell (2014) or newer. Older hardware should use the mostly unmaintained intel-vaapi-driver driver.
          :::
        '';
      };

      extraPackages32 = lib.mkOption {
        type = types.listOf types.package;
        default = [];
        example = lib.literalExpression "with pkgs.pkgsi686Linux; [ intel-media-driver intel-vaapi-driver ]";
        description = ''
          Additional packages to add to 32-bit OpenGL drivers on 64-bit systems.
          Used when {option}`driSupport32Bit` is set. This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.

          ::: {.note}
          intel-media-driver supports hardware Broadwell (2014) or newer. Older hardware should use the mostly unmaintained intel-vaapi-driver driver.
          :::
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.driSupport32Bit -> pkgs.stdenv.isx86_64;
        message = "Option driSupport32Bit only makes sense on a 64-bit system.";
      }
    ];

    systemd.tmpfiles.rules = [
      "L+ /run/opengl-driver - - - - ${package}"
      (
        if pkgs.stdenv.isi686
        then "L+ /run/opengl-driver-32 - - - - opengl-driver"
        else if cfg.driSupport32Bit
        then "L+ /run/opengl-driver-32 - - - - ${package32}"
        else "r /run/opengl-driver-32"
      )
    ];

    system-opengl.package = lib.mkDefault pkgs.mesa.drivers;
    system-opengl.package32 = lib.mkDefault pkgs.pkgsi686Linux.mesa.drivers;
  };
}
