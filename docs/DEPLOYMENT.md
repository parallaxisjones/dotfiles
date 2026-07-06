# Deployment – First Install and Ongoing Updates

## First Install with nixos-anywhere + disko (recommended)

- Requirements: reachable SSH host, working bootloader, and installer access (for ARM boards, Tow-Boot/U-Boot as needed).
- Command pattern:

```
nix run github:numtide/nixos-anywhere -- --flake .#<aarch64-system> <ssh-host>
```

- Use `disko` for partitioning; prefer a dry-run before destructive operations.

## macOS (nix-darwin) first install

- Build and activate: `nix run .#build-switch` (wraps `sudo darwin-rebuild switch --flake .#aarch64-darwin`).
- **Homebrew third-party tap trust (Homebrew 6+).** On a fresh machine the first `build-switch` activates fine, but the `brew bundle` step then refuses to install casks/formulae from any non-official tap:

  ```
  Error: Refusing to load cask <tap>/<cask> from untrusted tap <tap>.
  Run `brew trust --cask <tap>/<cask>` or `brew trust <tap>` to trust it.
  `brew bundle` failed! Failed to fetch <cask>
  ```

  Homebrew enforces `$HOMEBREW_REQUIRE_TAP_TRUST`; the `trusted: true` that our pinned (Apr 2025) nix-darwin writes into the generated Brewfile is **not** honored by Homebrew 6. Trust each non-official tap declared in `flake.nix` (`nix-homebrew.taps`) once, then re-run `build-switch` (or `brew install` the item directly). The official `homebrew/*` taps need no trust. Current third-party items:

  ```
  brew trust --cask tabularisdb/tabularis/tabularis   # tabularis (DB desktop app)
  brew trust --formula bastionzero/tap/zli            # zli
  ```

  Trust is recorded in `~/.homebrew/trust.json` — **per-machine** state that persists across rebuilds and is independent of the read-only nix-homebrew tap mount. It is not part of the Nix config, so it must be re-done on every new machine. Background and root cause: `docs/changes/2026-07-06-tabularis-and-darwin-skew.md`.

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
