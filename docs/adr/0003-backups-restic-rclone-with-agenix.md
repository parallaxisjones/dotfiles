# ADR 0003: Backups — restic + rclone, credentials via agenix

- Status: Accepted
- Date: 2025-08-27

## Context
NAS data requires offsite copies. We want incremental, encrypted backups and simple restore flows, managed declaratively with secrets.

## Decision
Use `restic` with an object store backend via `rclone` (e.g., B2/S3). Store credentials using `agenix`-managed age secrets. Schedule backups and prune policies through NixOS timers/services.

## Consequences
- Pros: Encrypted, incremental, deduplicated backups; portable repositories; simple restores.
- Cons: Object-store cost considerations; need credentials rotation and monitoring.

## Notes
- Define pruning/retention (e.g., daily 7, weekly 4, monthly 6).
- Periodically test restores.
- Keep bandwidth limits for initial seed.

## Alternatives
- Borg with remote repo; ZFS send/receive to remote host.

## Links
- docs/HELIOS64_DESIGN.md
