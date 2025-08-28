## Linting and Formatting Runbook

This repo standardizes on Nix tooling for .nix files and provides guidance for shell/markdown/yaml where useful. All commands are safe to run from the repo root.

### Nix formatting (nixpkgs-fmt)

- Check (CI mode):
```bash
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#nixpkgs-fmt -- --check $(git ls-files '*.nix')
```
- Apply fixes:
```bash
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#nixpkgs-fmt -- $(git ls-files '*.nix')
```

Notes:
- We use `git ls-files` to limit to tracked files and avoid formatting vendored/out-of-tree paths.

### Nix static analysis (statix)

- Check (no writes):
```bash
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#statix -- check .
```
- Apply safe fixes (where supported):
```bash
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#statix -- fix .
```

Configuration:
- `statix.toml` controls ignored patterns and rules. Prefer tuning the config over disabling rules inline.

### Nix dead code (deadnix)

- Report unused bindings/args:
```bash
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#deadnix -- .
```
- Enforce in CI (fail on findings):
```bash
nix run --extra-experimental-features 'nix-command flakes' nixpkgs#deadnix -- --fail .
```

Remediation tips:
- Replace unused lambda arguments with `_` (or `_arg` if referenced in docs).
- Remove unused `let` bindings or promote to module options if intent is configuration.

### Suggested pre-commit (optional)

If you use `pre-commit` locally, add this to `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: local
    hooks:
      - id: nixpkgs-fmt
        name: nixpkgs-fmt
        language: system
        entry: nix run nixpkgs#nixpkgs-fmt --
        files: "\.nix$"
      - id: statix
        name: statix check
        language: system
        entry: nix run nixpkgs#statix -- check
        files: "\.nix$"
```

### Shell/YAML/Markdown (as needed)

- Shell formatting:
```bash
nix run nixpkgs#shfmt -- -w -i 2 $(git ls-files '*.sh')
```
- YAML/JSON/Markdown via prettier (optional):
```bash
nix run nixpkgs#prettier -- --write $(git ls-files '*.yml' '*.yaml' '*.json' '*.md')
```

### CI parity

Typical CI steps mirror:
```bash
nix run nixpkgs#nixpkgs-fmt -- --check $(git ls-files '*.nix')
nix run nixpkgs#statix -- check .
nix run nixpkgs#deadnix -- --fail .
```
Fail locally before pushing to keep PRs clean.

### Troubleshooting

- Formatter changed whitespace in generated files: restrict scope with `git ls-files` or add a local ignore file.
- `deadnix` flags intentionally unused args: rename to `_` or add a comment where necessary, but prefer removing dead code.
- Use `nix flake check` for a broader health signal if available.


