# Convenience targets for this flake.
# Run `just` to list, `just deploy` to push the nixos host config from the laptop.

# Tailnet (or LAN) hostname of the always-on NixOS box.
nixos_host := "nixos"

# The nixosConfigurations attr is keyed by system string (see flake.nix),
# so the desktop/server host is `.#x86_64-linux`, NOT `.#nixos`.
nixos_attr := "x86_64-linux"

default:
    @just --list

# Build + switch the NixOS host remotely over SSH. Builds ON the server
# (--build-host) since a darwin laptop can't build Linux derivations locally.
deploy host=nixos_host:
    nixos-rebuild switch \
      --flake .#{{nixos_attr}} \
      --target-host parallaxis@{{host}} \
      --build-host parallaxis@{{host}} \
      --use-remote-sudo

# Dry-run: build the host config remotely without switching.
deploy-dry host=nixos_host:
    nixos-rebuild build \
      --flake .#{{nixos_attr}} \
      --build-host parallaxis@{{host}}

# Evaluate the host config locally (no build) — fast syntax/type check.
check:
    nix eval .#nixosConfigurations.{{nixos_attr}}.config.system.build.toplevel.drvPath
