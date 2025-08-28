# Apps

These are flake apps: runnable commands exposed by `flake.nix` and dispatched per system (e.g., `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`, `x86_64-darwin`). They wrap common actions so you don’t need to remember long commands.

Run them with:
```
nix run .#<app>
```

Examples:
- Darwin:
  - `nix run .#build` — build the current config
  - `nix run .#build-switch` — build and apply
  - `nix run .#rollback` — roll back to previous generation
- NixOS:
  - `nix run .#build-switch` — build and switch
  - `nix run .#install` — guided first install (if present for your arch)
  - `nix run .#install-with-secrets` — install flow with secrets (where present)

Notes:
- Apps are implemented in `apps/<system>/` and wired via `mkApp` in `flake.nix`.
- Some apps require SSH agent forwarding (for secrets or remote builders).
- The `install-with-secrets` scripts now copy this repo into `/mnt/etc/nixos` and install from there; they no longer fetch external templates.

## How app selection works

- `flake.nix` defines `apps` per system using `mkApp`. When you run `nix run .#build-switch` on a given machine, Nix picks the variant for that machine’s architecture and OS.
- App implementations live under `apps/<system>/`. For example, `apps/aarch64-darwin/build-switch` vs `apps/x86_64-linux/build-switch`.

## App catalog and rationale

Darwin (macOS):
- `build`: Build the current darwin configuration without activating it.
  - Why: Validate builds and catch errors quickly without changing your system.
- `build-switch`: Build and activate the darwin configuration in one step.
  - Why: One-liner for routine updates with rollback safety via generations.
- `apply`: Guided token replacement and setup (legacy helper; rarely needed now).
  - Why: Bootstrap only. Prefer editing `flake.nix` and modules directly.
- `copy-keys`, `create-keys`, `check-keys`:
  - Why: Helpers for SSH key setup/validation when working with builders or secrets.
- `rollback`:
  - Why: Quickly revert to the previous darwin generation if a change misbehaves.

NixOS (Linux):
- `build-switch`: Build and activate the NixOS configuration on the host.
  - Why: Routine updates with generations for safe rollback.
- `install`: Guided first install flow without secrets provisioning.
  - Why: Bare-minimum installer when secrets aren’t required up front.
- `install-with-secrets`: First install flow that stages this repo to `/mnt/etc/nixos` and runs `disko` before `nixos-install`.
  - Why: Repeatable, self-contained installs that match the flake exactly; no external template downloads.
- `apply`, `copy-keys`, `create-keys`, `check-keys`:
  - Why: Bootstrap and key management helpers during provisioning.

## Prerequisites and assumptions

- Nix with flakes enabled.
- For macOS apps: nix-darwin installed; optional nix-homebrew as wired in `flake.nix`.
- For install flows: running from the NixOS installer on the target machine.
- For secrets: ensure network access to fetch the `secrets` input (SSH agent or HTTPS).

## When to use these apps

- Day-to-day updates: `build-switch` on your machine (Darwin or NixOS).
- First-time NixOS installs: `install` or `install-with-secrets` from the installer environment with this repo checked out.
- Recovery: `rollback` on Darwin; on NixOS use GRUB/systemd-boot generations or `nixos-rebuild --rollback`.

## Why use apps instead of raw commands

- Consistency: Codifies best-practice flags and host-specific quirks per platform.
- Ergonomics: Short, memorable commands instead of long `nixos-rebuild`/`darwin-rebuild` incantations.
- Safety: Installer apps stage the exact repo state to `/mnt/etc/nixos`, minimizing drift.
- Reproducibility: Keeps first install and ongoing updates aligned with the same flake outputs.
