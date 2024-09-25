# Nix System OpenGL

> [!CAUTION]
> This repository is __HIGHLY EXPERIMENTAL!!!__ Do not choose to rely on this as a method in any production environment until it has been further tested. If you hit any issues, please [open a Github issue](https://github.com/soupglasses/nix-system-opengl/issues/new/choose).

## Installing with Nix Flakes

While this will be very induvidualized to how your `flake.nix` is written, generally a complete file would look like the following.

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

## Testing

> [!WARNING]
> If you already have system-manager installed, this will overwrite your configuration!
>
> See install section for how to install this into your profile.

To install the example system-manager config, you may run the following inside this folder.
```bash
nix run 'github:numtide/system-manager' -- switch --flake '.'
```

To verify if the graphics drivers work as expected, you can then run.
```bash
nix shell nixpkgs\#mesa-demos -c eglgears_wayland
nix shell nixpkgs\#mesa-demos -c eglgears_x11
```

Removing system-manager, and subsequently nix-system-opengl, you can run the command.
```bash
nix run 'github:numtide/system-manager' -- switch
# Note, this does not currently seem do remove folders such as `/run/opengl-driver` for you.
# See: https://github.com/numtide/system-manager/issues/116
```

