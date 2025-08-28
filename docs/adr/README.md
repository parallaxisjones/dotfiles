# Architecture Decision Records (ADR)

We capture key technical decisions as ADRs to provide context, rationale, and tradeoffs. Keep them short and actionable.

## Conventions
- Files live under `docs/adr/` and are numbered with zero-padded sequence (e.g., `0001-...`).
- Status: Proposed → Accepted/Rejected → Superseded (by NNNN).
- Keep decisions specific; split if a document tries to cover multiple topics.

## Template
See `0000-template.md` for a starting point. Create new ADRs by copying the template and incrementing the number.

## Index
- 0001 — Choose ZFS for Helios64 Storage (Accepted)
- 0002 — Networking on Helios64 — Prefer 1GbE Initially (Accepted)
- 0003 — Backups — restic + rclone, credentials via agenix (Accepted)
