## Agent skills

### Issue tracker

Issues live in GitHub Issues (`parallaxisjones/dotfiles`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary — needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Available skills

- **nix-profile-manager** (`.Codex/skills/nix-profile-manager/`) — manage local Nix profiles imperatively: install, search, and upgrade packages via `nix profile` without touching the system config. Read `SKILL.md` before running any `nix profile` commands; consult `references/` for flakes, package search, profile internals, and registry configuration.
