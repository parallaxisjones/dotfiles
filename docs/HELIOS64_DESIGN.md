# Helios64 NAS Design

## Goals
- Reproducible NixOS install on Helios64 (`aarch64-linux`).
- Stable ZFS storage with sensible defaults and tunables for RK3399.
- Core services later: SMB/NFS, backups, monitoring.
- Clear verification and operations runbooks.

## Current State
- Hardware: Kobol Helios64 (RK3399, 5-bay SATA, 4–8 GB RAM).
- Boot: U-Boot/Tow-Boot on SD/eMMC; NixOS root on SATA preferred.
- Storage: ZFS already provisioned on device; issues suspected (network port stability and/or memory pressure).

## Risks and Considerations
- 2.5GbE port may be unstable on some units; prefer 1GbE if needed.
- ZFS memory usage on low-RAM ARM boards; ARC sizing and scrubs need care.
- Power events can stress RAIDZ1; consider backup and periodic resilver tests.
- Kernel/ZFS version compatibility; pin channel and update steadily.

## Storage Design (ZFS)
- Pool name: `tank` (customizable).
- Recommended topology options (choose per disks available):
  - 2 disks: mirror.
  - 3–5 disks: RAIDZ1 (capacity-leaning, 1-disk fault tolerance).
  - 4–5 disks: RAIDZ2 (safer, capacity trade-off).
- ZFS props defaults:
  - `ashift=12`, `autotrim=on`, `compression=zstd`, `atime=off` for bulk data.
  - Snapshots via periodic service; labels with `com.sun:auto-snapshot=true` where desired.

### Dataset Layout (example)
- `tank/services` for system/service state (optional).
- `tank/data/shares` for SMB exports.
- `tank/data/media` for streaming libraries.
- `tank/backups` for local restic/borg targets.

### NixOS configuration snippets
```
# Enable ZFS and basics
boot.supportedFilesystems = [ "zfs" ];
services.zfs = {
  autoScrub.enable = true;
  trim.enable = true;
};

# Optional ARC cap for low-RAM systems (example: 1GiB)
# boot.kernelParams = [ "zfs.zfs_arc_max=1073741824" ];
```

## Verification and Health
- Pool/dataset:
  - `zpool status -v`
  - `zfs list -o name,used,avail,compressratio,mountpoint`
- Disks/SMART:
  - `smartctl -a /dev/sdX`
- Performance spot-checks:
  - `fio --name=seqwrite --rw=write --bs=1M --size=1G --filename=/tank/tmpfile`

## Monitoring & Ops
- Enable node-exporter and zfs metrics later; ship logs to a collector.
- Scrub policy: monthly; SMART long test quarterly.
- Drive replacement playbook (short):
  1) Identify failed device: `zpool status`.
  2) Offline if needed: `zpool offline tank <dev>`.
  3) Replace disk physically.
  4) Label new disk and attach: `zpool replace tank <old-dev> <new-dev>`.
  5) Monitor resilver: `zpool status`.

## Network
- Prefer the 1GbE port if 2.5GbE proves unstable; lock link speed at switch if needed.

## Deployment Plan
- Use `nixos-anywhere` with `disko` for first install.
- Configure minimal host, verify device tree, then enable ZFS and datasets.
- Add services incrementally (SMB, NFS, backups) in dedicated modules.

## Follow-up Checklist
- Storage
  - [ ] Confirm `zpool status` clean; record topology and serials
  - [ ] Set ARC cap if memory pressure observed; re-evaluate after 1 week
  - [ ] Schedule monthly scrub; review results
- Networking
  - [ ] Lock to 1GbE; run `iperf3` baseline; capture dmesg for 24h
  - [ ] Re-test 2.5GbE after kernel updates; create ADR if switching
- Backups
  - [ ] Configure restic repo and credentials via agenix
  - [ ] Seed backup with bandwidth limits; schedule prune/retention
  - [ ] Test restore quarterly; document steps

## Open Questions
- Final topology (RAIDZ1 vs RAIDZ2) based on actual disk count and failure domain.
- ARC limit target after observing real workload (start at 1–2 GiB on 4 GB RAM).

## References
- docs/HELIOS64.md for install notes and commands.
- docs/adr/0001-choose-zfs-for-helios64.md (ZFS decision)
- docs/adr/0002-networking-1g-vs-2_5g.md (Networking choice)
- docs/adr/0003-backups-restic-rclone-with-agenix.md (Backups strategy)
