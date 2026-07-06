# Change: Tabularis cask + nix-darwin/nixpkgs skew fixes

- Date: 2026-07-06
- PR / commit: PR TBD (changes currently in the working tree; last merged PR was #89)
- Related ADRs: none

## What changed

- Added the **Tabularis** database desktop app as a Homebrew cask:
  - New flake input `tabularis-tap` → `github:TabularisDB/homebrew-tabularis` (`flake = false`) in `flake.nix`, threaded through the `outputs = { … }` args.
  - Mapped `"TabularisDB/homebrew-tabularis" = tabularis-tap;` under `nix-homebrew.taps` in `flake.nix`.
  - Added `"tabularis"` to `modules/darwin/casks.nix`.
  - Locked the input in `flake.lock` (`042c2e2`, 2026-07-01) — no other inputs bumped.
- Fixed a **pre-existing** broken darwin build (unrelated to Tabularis, blocking every `build-switch`):
  - `documentation.enable = false;` in `hosts/darwin/configuration.nix`.
  - `system.tools.darwin-uninstaller.enable = false;` in `hosts/darwin/configuration.nix`.
- Fixed a second pre-existing break: bumped the `_1password-gui` source hash in `overlays/_1password-gui-hash.nix`
  (`sha256-Rbac0…` → `sha256-bZD8…`).

## What caused it (trigger / root cause)

The trigger was a simple request: "install Tabularis via `brew tap … && brew install --cask tabularis`." That surfaced four deeper causes:

1. **Homebrew is declarative here.** This repo runs `nix-homebrew` with `mutableTaps = false`, so imperative `brew tap` is locked out and casks are reconciled from config. Tabularis had to be added as a flake-input tap + a `casks.nix` entry, following the existing `bastionzero-tap` pattern — not installed by hand.

2. **nix-darwin ↔ nixpkgs version skew.** The `darwin` input is pinned to ~Apr 2025 (`43975d7`) while nixpkgs is ~Jul 2026 (`d407951`) after recent `chore: update flake.lock` PRs. The old nix-darwin builds its manual with `nixos-render-docs … --toc-depth`, a flag the current nixpkgs removed (_"--toc-depth has been removed, use --sidebar-depth instead"_), so `darwin-manual-html` failed. `documentation.enable = false` removed the manual from the top-level system, but `pkgs/darwin-uninstaller` evaluates its **own** default (docs-enabled) system via `eval-config.nix`, which dragged `darwin-manual-html` back into the closure through `system-path` — hence also disabling the uninstaller tool.

3. **1Password re-published its artifact.** 1Password served new bytes for 8.12.26 at the same URL, so the fixed-output hash pinned in `overlays/_1password-gui-hash.nix` no longer matched. `_1password-gui` is pulled into the darwin build via git SSH signing (`sshProgram = "${pkgs._1password-gui}/bin/op-ssh-sign"` in `modules/shared/home-manager.nix`). Updating the hash to the currently-served value is this repo's established pattern for 1Password's periodic re-publishes.

4. **Homebrew 6 tap-trust gate.** After a successful `darwin-rebuild switch`, `brew bundle` still refused the cask: _"Refusing to load cask … from untrusted tap."_ Homebrew 6.0.1 enforces `$HOMEBREW_REQUIRE_TAP_TRUST`, so non-official taps must be explicitly trusted. The pinned nix-darwin emits `cask "tabularis", trusted: true` in the Brewfile, but Homebrew 6 no longer honors that flag (another skew). The fix is a one-time `brew trust --cask tabularisdb/tabularis/tabularis`, which records trust in `~/.homebrew/trust.json` — local machine state, independent of the read-only nix-homebrew tap mount, and persistent across rebuilds (but absent on a fresh machine).

## How it was done

- Verified the tap repo/cask names via the GitHub API (`TabularisDB/homebrew-tabularis`, branch `main`, `Casks/tabularis.rb`).
- Added the input, tap mapping, and cask; ran `nix flake lock` to add only the new input.
- Traced the manual failure with `nix why-depends --derivation` to find the `darwin-uninstaller → inner system → system-path → darwin-manual-html` chain, then read `pkgs/darwin-uninstaller/default.nix` and `modules/documentation/default.nix` in the pinned nix-darwin source to confirm the two toggles needed.
- Took the 1Password `got:` hash straight from the build's mismatch error.

## Verification

- `nix build .#darwinConfigurations.aarch64-darwin.system` succeeds and produces a `darwin-system-26.11` result (no sudo / switch required to build).
- `nix eval … .config.homebrew.casks` shows `cask "tabularis", trusted: true`.
- `nix eval … .config.nix-homebrew.taps` includes `TabularisDB/homebrew-tabularis`.
- Dry-build build plan no longer contains `darwin-manual-html` / `darwin-help` / `render-docs`.
- `sudo darwin-rebuild switch --flake .#aarch64-darwin` (or `nix run .#build-switch`) succeeds and switches the generation; the Homebrew activation taps the repo declaratively.
- Installing the cask required the one-time trust above, then it installed cleanly: `brew trust --cask tabularisdb/tabularis/tabularis` → `tabularis 0.13.4` in `/Applications/tabularis.app` (confirmed via `brew list --cask`).

## Links

- CHANGELOG entry: [`CHANGELOG.md`](../../CHANGELOG.md) → 2026-07-06
- Source files: `flake.nix`, `flake.lock`, `modules/darwin/casks.nix`, `hosts/darwin/configuration.nix`, `overlays/_1password-gui-hash.nix`
- Pattern reference: the existing `bastionzero-tap` wiring in `flake.nix`
- New-machine runbook: `docs/DEPLOYMENT.md` → "macOS (nix-darwin) first install" (Homebrew tap-trust step)
- Upstream: nixpkgs `nixos-render-docs` removal of `--toc-depth` (use `--sidebar-depth`); 1Password 8.12.26 artifact re-publish
- Related ADRs: none
