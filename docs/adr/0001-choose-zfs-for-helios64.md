# ADR 0001: Choose ZFS for Helios64 Storage

- Status: Accepted
- Date: 2025-08-27

## Context
The Helios64 NAS (RK3399) will host important data. The device already uses ZFS. We need a reproducible and maintainable storage layer with snapshots, scrubs, and data integrity features.

## Decision
Use ZFS as the primary storage layer on the Helios64. Prefer RAIDZ2 when disk count allows; otherwise RAIDZ1 or mirrors depending on capacity and resilience needs. Enable compression (zstd), autotrim, and regular scrubs.

## Consequences
- Pros:
  - End-to-end checksums, snapshots, send/receive, robust self-healing.
  - Mature NixOS integration.
- Cons:
  - Higher memory usage on low-RAM ARM boards.
  - Kernel/module coupling; updates must be paced.

## Notes and Mitigations
- Consider ARC cap (e.g., 1–2 GiB) if memory pressure observed.
- Prefer stable channel pinning and staged updates.
- If 2.5GbE instability impacts workload, prefer 1GbE and/or set link speed.

## Alternatives Considered
- mdraid + ext4/btrfs: simpler, lower memory, but weaker integrity features compared to ZFS.

## Links
- docs/HELIOS64_DESIGN.md
- docs/HELIOS64.md
