# Change Notes

Deeper explanations of **what changed and what caused it**. Where the root [`CHANGELOG.md`](../../CHANGELOG.md) is the scannable, one-line-per-change surface log, change notes are the narrative behind an entry: the trigger, the root cause, how it was done, and how it was verified.

## How this differs from ADRs

- **ADRs (`docs/adr/`)** are _timeless, decision-centric_: "we decided to use ZFS." Their status reflects current validity; they're superseded, not dated-out.
- **Change notes (`docs/changes/`)** are _temporal, change-centric_: "on this date these things changed, and here's what forced them." They are a historical record and don't get superseded.

If a change embodies a lasting structural decision, write an ADR too and cross-link it.

## Conventions

- Files are named `YYYY-MM-DD-slug.md` (dated, so they sort chronologically).
- One note per meaningful change or batch of related changes. Keep it specific; split if it sprawls across unrelated topics.
- Each note should link back to its `CHANGELOG.md` line, the source files it touched, and any related ADRs.

## Template

Copy [`_template.md`](_template.md) and rename it to `YYYY-MM-DD-your-slug.md`.

## Index

- 2026-07-06 — [Tabularis cask + nix-darwin/nixpkgs skew fixes](2026-07-06-tabularis-and-darwin-skew.md)
