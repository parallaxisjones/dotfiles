# Homelab Roadmap

This roadmap breaks work into phases. Each phase is shippable and can be split into small issues.

## Phase 0 · Current State and Goals
- Powerful x86_64 NixOS builder reachable via SSH alias `nixos` (Ryzen 9).
- macOS M3 (aarch64-darwin) as day-to-day workstation.
- Goal: deploy and manage a Helios64 (RK3399, aarch64) NAS with NixOS, reproducibly.

Deliverables:
- Inventory of builder and mac flows (remote builders).
- Initial Helios64 install plan and risks.

## Phase 1 · Cross-Arch Build & Remote Builders
- Enable aarch64 builds on the x86_64 builder (binfmt/QEMU).
- Document dev flows for mac M3 to offload builds to the x86 builder.

Deliverables:
- docs/REMOTE_BUILDERS.md with setup and verification steps. — Done
- Optional: CI job to lint/format (statix, nixpkgs-fmt). — Done

## Phase 2 · Helios64 First Install
- Prepare boot media and ensure U-Boot/Tow-Boot.
- Use nixos-anywhere with disko to provision the NAS.
- Minimal host config: networking, SSH, device tree, basic storage.

Deliverables:
- docs/HELIOS64.md with DTB, storage options, and first boot checklist. — Done
- docs/HELIOS64_DESIGN.md for architecture, storage topology, and ops. — Done
- docs/adr/0001-choose-zfs-for-helios64.md to record storage decision. — Done
- docs/DEPLOYMENT.md for first install commands. — Done

## Phase 3 · Services and Storage
- Decide on storage (ZFS/mdraid/btrfs) and implement.
- Add essential services (SMB/NFS, backup, monitoring, exporters).

Deliverables:
- Storage module and service modules under modules/nixos/.
- Service runbooks in docs/.

Next:
- Add NixOS module stubs:
  - ZFS maintenance (autoscrub, health reporting)
  - Backups (restic + rclone + agenix)
  - Networking test helpers (pin 1GbE, iperf3 service)

## Phase 4 · Continuous Deployment
- Wire deploy-rs for ongoing updates.
- Optional: add Colmena for fleet orchestration.

Deliverables:
- Flake wiring for deploy-rs and example commands.
- README updates, rollbacks guide.

## Phase 5 · Hardening & Observability
- Add firewall, fail2ban/sshguard, system health checks.
- Add metrics/logging (Prometheus node exporter, Loki/Vector optional).

Deliverables:
- Security and observability modules and docs.

### Phase 3.x · Secrets consolidation (agenix + flake input)
- Standardize `secrets` flake input (SSH deploy key or HTTPS fallback).
- Pass `user` via `specialArgs` to avoid hardcoded usernames.
- Centralize public keys under `modules/shared/secrets/keys/` and reference with `builtins.readFile`.
- Remove legacy template paths; fix typos and stale references.
- Define a minimal set of age secrets (GitHub SSH, signing keys, app tokens) and document rotation.
- Add installer checklist for fetching `secrets` input on first build (network, SSH agent, or HTTPS).

## Backlog / Ideas
- Tailscale/WireGuard access
- Offsite backups (restic/borg) and snapshot policies
- Self-hosted services catalog

### Backlog · CI/CD and GitHub Actions
- Add `nixpkgs-fmt --check` step; fail PRs on formatting issues. — Done
- Add Cachix push on main builds; leverage binary cache across hosts. — Added job (needs secret)
- Add matrix eval/build for `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`, `x86_64-darwin`.
- Add flake inputs update workflow (scheduled) with PR auto-label `automerge`.
- Attach `nix flake show` and `nix flake check` summaries to PR. — Done

### Backlog · Virtualization & Kubernetes Options
- Evaluate k3s on bare metal NixOS vs. lightweight VMs/containers per service.
- Firecracker/microVMs research for isolation; compare with `podman` + cgroups.
- If K8s: decide control-plane location (builder vs. NAS), storage class, ingress, and secrets.
- If non-K8s: standardize systemd services/containers modules and service discovery.

### Backlog · Core Services
- Trading bot service module: env flags, secrets via agenix, logs persistence.
- BitTorrent (qbittorrent/rtorrent) with WebUI, hardening, and speed limits.
- Plex/Emby/Jellyfin: hardware transcoding options; storage mounts and backups.
- Reverse proxy (Caddy/Traefik/Nginx) with TLS, auth, and dashboards.

### Backlog · Backups and DR
- Snapshot policy for critical data; schedule (hourly/daily/weekly) and retention.
- Offsite backups: restic with rclone (S3/B2) or borg to a remote repo.
- Encrypted secrets for backup credentials via agenix.
- Recovery runbook: restore checklists and periodic restore tests.

### Backlog · Personal Lakehouse (Financial Data)
- Storage layout for raw/bronze/silver/gold zones under a dedicated dataset.
- Ingestion tasks from trading bot outputs; schema and partitioning design.
- DuckDB/SQLite for local analytics; optional Spark/Polars runners.
- Metadata catalog (simple) and scheduled compaction/cleanup jobs.
- Dashboarding options (Metabase/Superset) with read-only credentials.
