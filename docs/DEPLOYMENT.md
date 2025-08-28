# Deployment – First Install and Ongoing Updates

## First Install with nixos-anywhere + disko (recommended)
- Requirements: reachable SSH host, working bootloader, and installer access (for ARM boards, Tow-Boot/U-Boot as needed).
- Command pattern:
```
nix run github:numtide/nixos-anywhere -- --flake .#<aarch64-system> <ssh-host>
```
- Use `disko` for partitioning; prefer a dry-run before destructive operations.

## Ongoing updates with deploy-rs (recommended)
- Command pattern:
```
nix run github:serokell/deploy-rs -- --flake .#<node>
```
- Configure `deploy.nodes.<node>` in your flake to point at the host (SSH alias, user, activation path).

## Rollbacks
- NixOS: `sudo nixos-rebuild --rollback switch` or select previous generation at boot.
- macOS (nix-darwin): `darwin-rebuild --rollback switch`.

## Tips
- Always `nix flake show` and/or `nix build` first for the target system.
- Keep deployments small and frequent for easy rollbacks.
