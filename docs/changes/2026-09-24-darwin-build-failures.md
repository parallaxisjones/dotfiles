# Change: Restore the Darwin build and propagate helper failures

- Date: 2026-09-24
- Related ADRs: none

## What changed and why

The dependency update moved 1Password to 8.12.34, but the Darwin overlay kept
overriding its source hash with the hash for the earlier 8.12.26 archive. The
pinned nixpkgs already provides the correct hash for 8.12.34:
`sha256-Tw15A3rw/wASCmxi/6/lGNO8YUC17PegzvDQW/MroR0=`.
Removed `overlays/_1password-gui-hash.nix` so package versions and their hashes
are updated together through nixpkgs.

The failed build also exposed an error-handling bug in the Darwin app helpers.
The flake invokes them with `bash`, so `-e` in their shebang was ignored. Both
helpers now use explicit `set -eu`, quote forwarded arguments, and use `printf`
to render colors consistently. A failed sync, build, activation, or cleanup stops
the helper before it prints a success message. The build-only helper now reports
a completed build rather than claiming to have switched generations.

## Verification

- Built `darwinConfigurations.aarch64-darwin.pkgs._1password-gui` successfully.
- Regression tests run the helpers through bash with mocked external commands,
  covering failures at every stage, the success path, and argument boundaries.
- CI runs these tests with `python3 tests/test_darwin_build_scripts.py`.

## Links

- [Changelog](../../CHANGELOG.md#unreleased)
- [Build and switch helper](../../apps/aarch64-darwin/build-switch)
- [Build helper](../../apps/aarch64-darwin/build)
- [Regression tests](../../tests/test_darwin_build_scripts.py)
