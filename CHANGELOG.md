# Changelog

All notable changes to this repo are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). This repo has no
tagged releases or semver, so changes are grouped under **dated** sections
instead of version numbers, with `[Unreleased]` at the top for in-flight work.

Entries are surface-level and PR-referenced. Deeper explanations of _what
changed and what caused it_ live in [`docs/changes/`](docs/changes/).

## [Unreleased]

## 2026-07-06

### Added

- Tabularis DB desktop app as a Homebrew cask, via a new declarative `TabularisDB/homebrew-tabularis` tap (flake input) and a `tabularis` entry in `modules/darwin/casks.nix`. Note: Homebrew 6 requires a one-time `brew trust --cask tabularisdb/tabularis/tabularis` before the cask installs. ([#90](https://github.com/parallaxisjones/dotfiles/pull/90))

### Fixed

- Darwin system build failing on `darwin-manual-html`: the pinned nix-darwin (Apr 2025) renders its manual with the now-removed `nixos-render-docs --toc-depth` flag under current nixpkgs. Disabled the manual + uninstaller (`documentation.enable = false`, `system.tools.darwin-uninstaller.enable = false`) in `hosts/darwin/configuration.nix`. ([#90](https://github.com/parallaxisjones/dotfiles/pull/90))
- `_1password-gui` fixed-output hash mismatch after 1Password re-published the 8.12.26 artifact; updated the pinned hash in `overlays/_1password-gui-hash.nix`. ([#90](https://github.com/parallaxisjones/dotfiles/pull/90))

→ details: [`docs/changes/2026-07-06-tabularis-and-darwin-skew.md`](docs/changes/2026-07-06-tabularis-and-darwin-skew.md)
