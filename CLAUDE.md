## Agent skills

### Issue tracker

Issues live in GitHub Issues (`parallaxisjones/dotfiles`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary — needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Change tracking

Record notable changes in two places: surface-level lines in root `CHANGELOG.md`, and deeper "what changed and what caused it" notes in `docs/changes/` (dated `YYYY-MM-DD-slug.md` entries). See `docs/changes/README.md`.

### Available skills

- **nix-profile-manager** (`.claude/skills/nix-profile-manager/`) — manage local Nix profiles imperatively: install, search, and upgrade packages via `nix profile` without touching the system config. Read `SKILL.md` before running any `nix profile` commands; consult `references/` for flakes, package search, profile internals, and registry configuration.
