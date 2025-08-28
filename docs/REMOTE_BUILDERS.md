# Remote Builders (x86_64 builder + macOS M3 dev)

## Goals
- Build `aarch64-linux` and `x86_64-linux` derivations on the powerful x86_64 NixOS builder (SSH alias `nixos`).
- From macOS M3, offload builds to the builder transparently.

## Builder setup (NixOS)
- Enable ARM emulation if building ARM locally:
```
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```
- Allow your user and set substituters as in `hosts/nixos` and `modules/shared`.

## Controller (macOS) configuration
- Ensure SSH access to the builder via alias `nixos` with keys.
- Configure remote builders in `/etc/nix/nix.conf` or via NixOS options where applicable:
```
builders-use-substitutes = true
max-jobs = 0
builders = @/etc/nix/machines
```
- Example `/etc/nix/machines` entry:
```
nixos x86_64-linux / - 8 1 kvm,big-parallel
```

## Verifying
- List systems: `nix eval .#nixosConfigurations --apply builtins.attrNames`
- Test remote build for a target system: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- From macOS, ensure the build happens on `nixos` (check load/derivation logs).
