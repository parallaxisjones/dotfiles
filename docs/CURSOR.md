## Cursor Agent Guide for this repo

This repo manages macOS (nix-darwin) and NixOS hosts using flakes, with shared modules and overlays.

- **Primary entry points**: `flake.nix`, `hosts/darwin/configuration.nix`, `hosts/nixos/configuration.nix`
- **Shared modules**: `modules/**` (don’t break inputs or imports)
- **Generated files**: `hosts/nixos/hardware-configuration.nix` is auto-generated. Do not edit. Lint is configured to ignore it via `statix.toml`.
- **Linting**: `statix` runs in CI. Fix warnings by consolidating repeated keys into nested attribute sets.
- **Secrets**: Managed with `agenix`; see `modules/shared/secrets.nix`. Don’t commit secrets. Keep age files in external secrets repo.

### Conventions
- **Attrs nesting**: Prefer nested sets to repeated keys, e.g. use `services = { xserver = { ... }; };`
- **macOS defaults**: Use `system = { stateVersion; primaryUser; defaults = { ... }; };` rather than repeated `system.*` keys.
- **Do not touch**: `hosts/nixos/hardware-configuration.nix`. Changes belong in `hosts/nixos/configuration.nix` or modules.
- **Overlays**: Add new overlays in `overlays/*.nix` and they are auto-imported by `flake.nix`.

### Common commands
- Build/switch (macOS): `nix run .#build-switch`
- Build/switch (Linux): `nix run .#build-switch`
- Lint: `nix run nixpkgs#statix -- check .`

### CI expectations
- Lint must be clean. If a generated file trips lint, add/adjust `statix.toml` ignores rather than editing the generated file.

### PR and commit preferences
- Include JIRA ticket in branch name when applicable and tag commits with `@ai-code`.

### When adding modules
- Keep host-specific config in `hosts/**`.
- Keep reusable logic under `modules/**` and wire into hosts via `imports`.
- Prefer options under existing namespaces (e.g., `services.*`, `programs.*`, `networking.*`).


