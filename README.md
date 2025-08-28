# Homelab: NixOS + macOS Fleet Configurations

This repo is the single source of truth for configuring every machine on my network: NixOS hosts (x86_64, aarch64) and macOS via nix-darwin. It uses flakes for reproducible, declarative builds across architectures.

## Vision

- Unify all hardware under one reproducible config (hosts + shared modules + overlays).
- Push builds to a powerful x86_64 builder; develop on macOS M3 without local compile pain.
- Treat NAS (Helios64) as a first-class citizen with clear storage, services, and ops.
- Ship small, frequent changes with safe rollbacks and documented runbooks.

## Roadmap (high-level)

- Phase 0: Current state, goals, inventory — builder + mac flows.
- Phase 1: Cross-arch builds and remote builders — documented and working. (Done)
- Phase 2: Helios64 first install — boot, disko, minimal host setup. (Done; see docs)
- Phase 3: Services & storage — ZFS/btrfs/mdraid decision, SMB/NFS, backups, exporters.
- Phase 4: Continuous deployment — deploy-rs wiring and rollbacks guidance.
- Phase 5: Hardening & observability — firewall, sshguard, metrics/logging.

See `docs/ROADMAP.md` for details and backlog.

## Structure

- `flake.nix`: inputs/outputs, `apps`, dev shells, and host outputs.
- `hosts/`: host-specific configurations (Linux and Darwin).
- `modules/`: shared modules (NixOS, Home Manager, shared config).
- `overlays/`: package overlays (customizations/additions).
- `apps/`: runnable helper scripts exposed as flake apps per system.
- `docs/`: deployment, remote-builders, Helios64 install and design notes.

## Usage

- Show flake targets:
  - `nix flake show`
- Build a host locally (example):
  - `nix build .#nixosConfigurations.helios64.config.system.build.toplevel`
- Switch on NixOS (on the target host):
  - `sudo nixos-rebuild switch --flake .#aarch64-linux`
- Darwin switch:
  - `darwin-rebuild switch --flake .#aarch64-darwin`

### Using flake apps

Apps are pre-wired scripts that run under `nix run .#<app>`. They are defined per system in `flake.nix`, and the repo provides implementations in `apps/<system>/`.

Common examples:
- On macOS:
  - `nix run .#build` — build the current Darwin config
  - `nix run .#build-switch` — build and activate Darwin config
  - `nix run .#rollback` — roll back to previous generation
- On NixOS:
  - `nix run .#build-switch` — build and activate NixOS config
  - `nix run .#install` — guided first install (where provided)
  - `nix run .#install-with-secrets` — install flow with secrets provisioning

Notes:
- Apps are system-specific; the correct variant is selected by your machine’s architecture (e.g., `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`).
- Some scripts expect SSH forwarding for secrets or remote builders. See `docs/DEPLOYMENT.md` and `docs/REMOTE_BUILDERS.md`.

## Remote builders

Use a beefy x86_64 NixOS builder to compile `aarch64-linux` and `x86_64-linux`, and offload from macOS M3.

Quick setup:
- On the builder (NixOS):
  - Enable ARM emulation if needed:
    ```nix
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    ```
  - Ensure your user can act as a builder and that SSH is reachable via alias `nixos`.
  - Example `/etc/nix/machines` entry:
    ```
    nixos x86_64-linux / - 8 1 kvm,big-parallel
    ```
- On macOS (controller):
  - Ensure SSH access to the builder via alias `nixos` and loaded keys (`ssh-add -l`).
  - Configure remote builders (e.g., `/etc/nix/nix.conf`):
    ```
    builders-use-substitutes = true
    max-jobs = 0
    builders = @/etc/nix/machines
    ```

Verify:
- List systems in this flake: `nix eval .#nixosConfigurations --apply builtins.attrNames`
- Test remote build: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
  (from macOS, the work should occur on `nixos`).

See `docs/REMOTE_BUILDERS.md` for details.

## Helios64 (NAS)

- First install, storage decisions, and design notes:
  - `docs/HELIOS64.md`, `docs/HELIOS64_DESIGN.md`, ADRs in `docs/adr/`
- Deployment steps: `docs/DEPLOYMENT.md`

## Requirements

- Nix with flakes enabled.
- For macOS: nix-darwin installed; optional nix-homebrew integration (provided).
- For secrets: agenix and a private secrets repo (flake input wired in `flake.nix`).

## Status

- Cross-arch remote builds: Done
- Helios64 initial planning/install docs: Done
- Next up: storage + services modules, deploy-rs, hardening/observability

## Documentation

- `docs/ROADMAP.md` – phased plan and current state
- `docs/HELIOS64.md` – RK3399/Helios64 checklist and install notes
- `docs/REMOTE_BUILDERS.md` – x86 builder and macOS M3 flows
- `docs/DEPLOYMENT.md` – deploy-rs and nixos-anywhere usage
- `docs/BOOTSTRAP_KEYS.md` – bootstrap and key management guide
