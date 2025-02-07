<!--
SPDX-FileCopyrightText: 2024 Abhiram <axel@foss.life>
SPDX-FileCopyrightText: 2024 SoupGlasses <sofi+git@mailbox.org>
SPDX-FileCopyrightText: 2025 SoupGlasses <sofi+git@mailbox.org>

SPDX-License-Identifier: CC-BY-4.0
-->

<p align="center">
    <img width="256" height="256" src="./static/nix-system-graphics.svg">
</p>

# Nix System Graphics

Run graphics accelerated programs built with Nix on _any_ Linux distribution. Works with both OpenGL and Vulkan seamlessly.

## Table of contents

- [Comparison Table](#comparison-table)
- [Installing with Nix Flakes](#installing-with-nix-flakes)
- [Extra Graphical Packages](#extra-graphical-packages)
- [Nvidia Support](#nvidia-support)
- [But why another Nix-with-OpenGL project?](#but-why-another-nix-with-opengl-project)
- [Acknowledgements](#acknowledgements)


## Comparison Table

| | [**NixGL**](https://github.com/nix-community/nixGL) | [**nix-gl-host**](https://github.com/numtide/nix-gl-host/) | [**nix-system-graphics**](https://github.com/soupglasses/nix-system-graphics) |
|---|:-:|:-:|:-:|
| Requires no wrapping? (no `nixgl ...`) | ❌ | ❌ | ✅ |
| Works with AMD/Intel? (Mesa) | ✅ | ❌ | ✅ |
| Works with Nvidia? (Proprietary) | ✅ | ✅ | ⚠️[⁴](#ref-4) |
| Works with `nix run nixpkgs#...`? | ⚠️[¹](#ref-1) | ⚠️[¹](#ref-1) | ✅ |
| Nix program can launch system apps? | ❌[²](#ref-2) | ❌[²](#ref-2) | ✅ |
| Is it Open Source? | ❌[³](#ref-3) | ✅ (Apache-2.0) | ✅ (MIT) |

1. <a name="ref-1"></a> Requires wrapping `nix run` with their wrapper before it works.
2. <a name="ref-2"></a> Can be done in very select cases under certain setups by manually changing internal variables. [Example](https://github.com/nix-community/nixGL/issues/116#issuecomment-1265042706).
3. <a name="ref-3"></a> NixGL is proprietary as it has no license information. See [this Github issue](https://github.com/nix-community/nixGL/issues/143) for more information.
4. <a name="ref-4"></a> While Nvidia is functional in nix-system-graphics, it requires manual effort to be kept in sync with the __exact__ version of the host. See [this Github comment](https://github.com/soupglasses/nix-system-graphics/issues/5#issuecomment-2443771338) for how this is done. [nix-gl-host](https://github.com/numtide/nix-gl-host/) may be a better alternative if the other above features of nix-system-graphics is not required, and a set-and-forget approach is desired.


## Installing with Nix Flakes

Ensure you have Nix installed with Flakes support enabled. If you do not have Nix installed already, you can do this by installing [Lix](https://lix.systems/install/) or using one of the [nix-installers](https://nix-community.github.io/nix-installers/) which enable this automatically. Alternatively, you may also [enable Flakes support manually](https://nixos.wiki/wiki/Flakes#Other_Distros.2C_without_Home-Manager) if you have installed Nix with another approach, but didn't enable Flakes support for you.

Now, adding a system-manager config will be very individualized to how your `flake.nix` is written, but generally a complete file would look like the following.

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

Then you can change into your system-manager config by using the `system-manager` package, either by installing it, running it in a development shell, or running it directly from the upstream flake URL, which we will do here.

```bash
nix run 'github:numtide/system-manager' -- switch --flake '.'
```

Lastly, to verify that the driver is now functioning on your system, you may run the following command.

```bash
nix shell 'nixpkgs#mesa-demos' --command glxgears
```


## Extra Graphical Packages

> [!IMPORTANT]
> This section is currently under testing and may not work as expected, so if you hit any issues or simply have success with this method, please [give feedback in the following Github issue #4](https://github.com/soupglasses/nix-system-graphics/issues/4).

You should be able to add VA-API/VDPAU/OpenCL/CUDA support similarly as you would in NixOS. Just add the relevant packages to `system-graphics.extraPackages` and `system-graphics.extraPackages32` as needed. Due to the variety of libraries that could possibly be added here, I recommend to read up on the relevant NixOS Wiki pages.

[Accelerated Video Playback](https://nixos.wiki/wiki/Accelerated_Video_Playback) | [AMD OpenCL](https://nixos.wiki/wiki/AMD_GPU#OpenCL) | [Nvidia CUDA](https://nixos.wiki/wiki/CUDA)

## Nvidia Support

> [!IMPORTANT]
> This section is currently under testing and may not work as expected, so if you hit any issues or simply have success with this method, please [give feedback in the following Github issue #5](https://github.com/soupglasses/nix-system-graphics/issues/5).

For a machine running the proprietary nvidia driver, the default mesa drivers will not work. So instead, please add the following to the config section of the system-manager config.

```nix
system-graphics.package = pkgs.linuxPackages.nvidia_x11.override { libsOnly = true; kernel = null; };
# Only required if you enable `system-graphics.enable32Bit`
system-graphics.package32 = (pkgs.linuxPackages.nvidia_x11.override { libsOnly = true; kernel = null; }).lib32;
```

There exists multiple versions of the NVIDIA driver, and they are typically incompatible with one another. So pay extra attention on [pinning the NVIDIA driver to the correct major version](https://nixos.wiki/wiki/Nvidia#Determining_the_Correct_Driver_Version). You should be able to see the current NVIDA driver version you have by running the command `cat /proc/driver/nvidia/version`.

If you still have issues, you can try to pin your driver to the [spessific version you are using manually](https://nixos.wiki/wiki/Nvidia#Running_Specific_NVIDIA_Driver_Versions), filling out the sha256 sums with `lib.fakeSha256` and removing them as you rebuild. This step however should generally not be needed, and the major version should be enough.

## But why another Nix-with-OpenGL project?

While there are existing solutions like [_nixGL_](https://github.com/nix-community/nixGL) and [_nix-gl-host_](https://github.com/numtide/nix-gl-host), they share a significant drawback: they rely on wrapping the execution of a Nix-built binary with internal environment variables, such as `LIBGL_DRIVER_PATH` and `__EGL_VENDOR_LIBRARY_FILENAMES`. You can find the full list of these variables as used by _nixGL_ [here](https://github.com/nix-community/nixGL/blob/310f8e49a149e4c9ea52f1adf70cdc768ec53f8a/nixGL.nix#L53-L62).

While this method works, it introduces a key limitation. If your application running via _nixGL_ calls another application, that second application also needs to support _nixGL’s_ specific versions of those graphics libraries, as these get propagated down through the environment variables. In simpler terms, system-installed applications tend to crash or behave unpredictably, as seen in this [issue](https://github.com/nix-community/nixGL/issues/116). You could try unsetting these environment variables on a per-application basis after launching, but this process is both error-prone and time-consuming.

Now, in contrast, _nix-system-graphics_ addresses this issue by populating `/run/opengl-driver` in the same way NixOS handles it. This eliminates the need to patch or wrap applications built from the Nix store, as they are already configured to use the `/run/opengl-driver` path by default for their `libGL` and `libvulkan` needs. Since there’s no need to wrap any binaries anymore, _all system applications work will work flawlessly, even when launched through a Nix-packaged application_. As a result, using Nix-packaged window managers like _i3_ or _sway_, or a graphically accelerated terminal emulator like _alacritty_, becomes a smooth and hassle-free experience, even when calling graphically accelerated system applications.

## Acknowledgements

Special thanks goes out to [@picnoir](https://github.com/picnoir) who created `nix-gl-host`, who also so kindly helped me with reflecting on the feasabilitiy of this project.
