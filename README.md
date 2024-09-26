# Nix System Graphics

> [!CAUTION]
> This repository is __EXPERIMENTAL__. Do not choose to rely on this as a method in any production environment until it has been further tested. If you hit any issues, please [open a Github issue](https://github.com/soupglasses/nix-system-graphics/issues/new/choose).

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

    nix-system-graphics = {
      url = "github:soupglasses/nix-system-graphics";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.system-manager.follows = "system-manager";
    };
  };

  outputs = { self, flake-utils, nixpkgs, system-manager, nix-system-graphics }: {
    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        nix-system-graphics.systemModules.default
        ({
          config = {
            nixpkgs.hostPlatform = "x86_64-linux";
            system-manager.allowAnyDistro = true;
            system-graphics.enable = true;
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


## Extra Graphical Packages

> [!IMPORTANT]
> This section is entirely untested and may not work, so if you have success with this method, please give feedback by [opening a Github issue](https://github.com/soupglasses/nix-system-graphics/issues/new/choose).

You should be able to add VA-API/VDPAU/OpenCL/CUDA support similarly as you would in NixOS. Just add the relevant packages to `system-graphics.extraPackages` and `system-graphics.extraPackages32` as needed. Due to the variety of libraries that could possibly be added here, I recommend to read up on the relevant NixOS Wiki pages.

[Accelerated Video Playback](https://nixos.wiki/wiki/Accelerated_Video_Playback) | [AMD OpenCL](https://nixos.wiki/wiki/AMD_GPU#OpenCL) | [Nvidia CUDA](https://nixos.wiki/wiki/CUDA)

## Nvidia Support

> [!IMPORTANT]
> This section is entirely untested and may not work, so if you have success with this method, please give feedback by [opening a Github issue](https://github.com/soupglasses/nix-system-graphics/issues/new/choose).

For a machine running the proprietary nvidia driver, the default mesa drivers will not work. So instead, please add the following to the config section of the system-manager config.
```nix
system-graphics.package = pkgs.linuxPackages.nvidia_x11.override { libsOnly = true; kernel = null; };
# Only required if you enable `system-graphics.enable32Bit`
# system-graphics.package32 = pkgs.pkgsi686Linux.linuxPackages.nvidia_x11.override { libsOnly = true; kernel = null; };
```

There exists many versions of the NVIDIA driver, and they are typically incompatible with one another. So extra attention should be put on [pinning the NVIDIA driver to a specific version](https://nixos.wiki/wiki/Nvidia#Running_Specific_NVIDIA_Driver_Versions). You should be able to see the current NVIDA driver version using the command `cat /proc/driver/nvidia/version`.


## But why another Nix-with-OpenGL project?

While there are existing solutions like [_nixGL_](https://github.com/nix-community/nixGL) and [_nix-gl-host_](https://github.com/numtide/nix-gl-host), they share a significant drawback: they rely on wrapping the execution of a Nix-built binary with internal graphical environment variables, such as `LIBGL_DRIVER_PATH` and `__EGL_VENDOR_LIBRARY_FILENAMES`. You can find the full list of these variables as used by _nixGL_ [here](https://github.com/nix-community/nixGL/blob/310f8e49a149e4c9ea52f1adf70cdc768ec53f8a/nixGL.nix#L53-L62).

While this method works, it introduces a key limitation. If your application running via _nixGL_ calls another application, that second application also needs to support _nixGL’s_ specific versions of those graphics libraries, as these get propagated down through these environment variables. In simpler terms, system-installed applications tend to crash or behave unpredictably, as seen in this [issue](https://github.com/nix-community/nixGL/issues/116). You could try unsetting these environment variables on a per-application basis after launching, but this process is both error-prone and time-consuming.

Now, in contrast, _nix-system-graphics_ addresses this issue by populating `/run/opengl-driver` in the same way NixOS handles it. This eliminates the need to patch or wrap applications built from the Nix store, as they are already configured to use the `/run/opengl-driver` path by default. Since there’s no need to wrap any binaries, _all system applications work will work flawlessly, even when launched through a Nix-packaged application_. As a result, using Nix-packaged window managers like _i3_ or _sway_, or a graphically accelerated terminal emulator like _alacritty_, becomes a smooth and hassle-free experience, even when calling graphically accelerated system applications.


## Acknowledgements

Special thanks goes out to [@picnoir](https://github.com/picnoir) who created `nix-gl-host`, who also so kindly helped me with reflecting on the feasabilitiy of this project.
