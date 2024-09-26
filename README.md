# Nix System OpenGL

> [!CAUTION]
> This repository is __HIGHLY EXPERIMENTAL!!!__ Do not choose to rely on this as a method in any production environment until it has been further tested. If you hit any issues, please [open a Github issue](https://github.com/soupglasses/nix-system-opengl/issues/new/choose).

Run graphics accelerated programs built with Nix on _any_ Linux distribution.


## Installing with Nix Flakes

While this will be very induvidualized to how your `flake.nix` is written, but generally a complete file would look like the following.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-system-opengl = {
      url = "github:soupglasses/nix-system-opengl";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.system-manager.follows = "system-manager";
    };
  };

  outputs = { self, flake-utils, nixpkgs, system-manager, nix-system-opengl }: {
    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        nix-system-opengl
        ({
          config = {
            nixpkgs.hostPlatform = "x86_64-linux";
            system-manager.allowAnyDistro = true;
            hardware.opengl.enable = true;
          };
        })
      ];
    };
  };
}
```

Then you can run it with `system-manager`, either by installing it, running a development shell, or run directly from their flake URL.

```bash
nix run 'github:numtide/system-manager' -- switch --flake '.'
```


## Nvidia Support

> [!IMPORTANT]
> This section is entirely untested and may not work, so if you have success with this method, please give feedback by [opening a Github issue](https://github.com/soupglasses/nix-system-opengl/issues/new/choose).

For a machine running the proprietary nvidia driver, the default mesa drivers will not work. So instead, please add the following to the config section of the system-manager config.
```nix
hardware.opengl.package = pkgs.linuxPackages.nvidia_x11.override { libsOnly = true; kernel = null; };
# Only required if you enable `hardware.opengl.driSupport32Bit`
# hardware.opengl.package32 = pkgs.pkgsi686Linux.linuxPackages.nvidia_x11.override { libsOnly = true; kernel = null; };
```

There exists many versions of the NVIDIA driver, and they are typically incompatible with one another. So extra attention should be put on [pinning the NVIDIA driver to a spessific version](https://nixos.wiki/wiki/Nvidia#Running_Specific_NVIDIA_Driver_Versions). You should be able to see the current NVIDA driver version using the command `cat /proc/driver/nvidia/version`.


## But why another nix with opengl project?

While previous solutions such as `nixGL` and `nix-gl-host` exist, they both share a major limitation by wrapping the call to a nix built binary with graphical environment variables such as `LIBGL_DRIVER_PATH` and `__EGL_VENDOR_LIBRARY_FILENAMES` (you can see the full list [here](https://github.com/nix-community/nixGL/blob/310f8e49a149e4c9ea52f1adf70cdc768ec53f8a/nixGL.nix#L53-L62)). While this approach works, it comes with a key limitation. If your application running through `nixGL` calls another application, that application need to also support `nixGL`'s version of the graphics libraries, since these environment variables get propagated. In other terms means [system installed applications freak out and crash](https://github.com/nix-community/nixGL/issues/116). While you can try to undo the environment by unsetting these per application. Its error prone and labour intensive.

In contrast, `nix-system-opengl` solves this problem is by instead populating `/run/opengl-driver` in the same way that NixOS would do it. This solves the problem of having to patch or wrap applications ran from the nix store, since the relevant packages are already built to point to `/run/opengl-driver` by default. And now since we aren't wrapping any binaries, _all system applications will work flawlessly, even when launched through a nix packaged application_. So using nix packaged window managers like `i3` or `sway`, or a graphically accelerated terminal emulator like `alacritty`, is now a completely seamless experience for both nix and system packages.


## Acknowledgements

Special thanks goes out to [@picnoir](https://github.com/picnoir) who created `nix-gl-host`, who also so kindly helped me with reflecting on the feasabilitiy of this project.
