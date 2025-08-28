# ADR 0002: Networking on Helios64 — Prefer 1GbE Initially

- Status: Accepted
- Date: 2025-08-27

## Context
Helios64 provides a 1GbE and a 2.5GbE port. Reports indicate 2.5GbE can be unstable on some units/kernels. Stability is prioritized for a NAS.

## Decision
Default to 1GbE for initial deployment. Re-evaluate 2.5GbE after baseline stability, kernel updates, and stress tests. Optionally force link speed on the switch if needed.

## Consequences
- Pros: Higher stability, fewer dropouts during resilvers/backups.
- Cons: Lower peak throughput vs. 2.5GbE.

## Notes
Capture test results (iperf3, dmesg logs) in follow-up ADR if 2.5GbE becomes viable.

## Alternatives
- Enable 2.5GbE now and accept potential instability.

## Links
- docs/HELIOS64_DESIGN.md
