# NixOS and macOS Configuration

This repository contains personal Nix configurations for both NixOS and macOS systems. It leverages the [Nix flakes](https://nixos.wiki/wiki/Flakes) feature to manage dependencies and ensure reproducibility across different machines.

This setup is used to manage environments for the users `parallaxis` and `pjones`.

## Key Features

- **Cross-Platform Management**: Manages configurations for both `NixOS` on Linux and macOS via `nix-darwin`.
- **Secrets Management**: Uses [agenix](https://github.com/ryantm/agenix) for managing secrets.
- **Modular Design**: Configurations are broken down into reusable `modules` and host-specific settings in the `hosts` directory.
- **Custom Packages**: `overlays` are used to provide custom packages and modifications.

## Structure

The repository is organized as follows:

- `flake.nix`: The main entry point. It defines all inputs (dependencies) and outputs (system configurations).
- `hosts/`: Contains the primary configuration for each individual machine.
- `modules/`: Contains shared and reusable configuration modules for packages, shell settings, etc.
- `overlays/`: Contains custom package definitions or modifications to `nixpkgs`.
- `apps/`: Contains configurations for various applications.

## Usage

To apply changes to the system configuration, edit the relevant Nix files and then run the following command:

```bash
nix run .#build-switch
```

This script will build the new configuration and activate it.
