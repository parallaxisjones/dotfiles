# Change: Fix evaluation after nixpkgs package and platform removals

- Date: 2026-09-24
- Related ADRs: none

## What changed

Removed HexChat from the NixOS desktop package list and retired the Intel macOS
target. The supported systems are now x86_64-linux, aarch64-linux (including
Helios64), and aarch64-darwin.

## What caused it

[CI run 35980011895](https://github.com/parallaxisjones/dotfiles/actions/runs/35980011895)
failed in the all-systems flake check on the automated flake-update PR. Its nixpkgs
revision removes HexChat because upstream archived it and it depends on GTK 2.
Nixpkgs 26.11 also removes x86_64-darwin support, so generating development shells
and system configurations for that platform fails evaluation.

## How it was done

- Removed `hexchat` from [packages-desktop.nix](../../modules/nixos/packages-desktop.nix).
- Removed `x86_64-darwin` from [flake.nix](../../flake.nix), which controls Darwin
  configurations, development shells, and app outputs.
- Removed the Intel Darwin evaluation from [CI](../../.github/workflows/ci.yml)
  and the obsolete `apps/x86_64-darwin` helper scripts.
- Updated the platform lists in the app documentation, roadmap, and agent guidance.

Intel Mac support is no longer needed; no separate stable nixpkgs pin was added.
The dependency lockfile is unchanged by this fix.

## Verification

Validation uses the failed PR's exact lockfile with `--reference-lock-file`,
`--no-write-lock-file`, and an empty secrets input, matching CI's public-input
evaluation without accessing private secrets.

- `nix flake check --all-systems` passed against the failed PR lockfile, including
  all three NixOS configurations and development shells for all supported systems.
- The same all-systems check also passed against the checkout's existing lockfile.
- Explicit evaluation of `darwinConfigurations.aarch64-darwin.system.drvPath`
  passed against that same lockfile.
- `statix check .`, `deadnix --fail .`, and `nixpkgs-fmt --check` for both changed
  Nix files passed.
- These checks validate evaluation; full system builds and remote CI were not run.

## Links

- [Changelog](../../CHANGELOG.md#unreleased)
- [Automated dependency update PR #95](https://github.com/parallaxisjones/dotfiles/pull/95)
