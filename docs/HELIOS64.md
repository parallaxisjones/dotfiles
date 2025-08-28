# Helios64 (RK3399) – NixOS Notes

Reference hardware intro/specs: https://wiki.kobol.io/helios64/intro/

## Checklist
- Target system: `aarch64-linux` (ARM64).
- Boot chain: ensure a working U-Boot/Tow-Boot on SD/eMMC; NixOS root may be on SATA.
- Device tree:
```
hardware.deviceTree.enable = true;
hardware.deviceTree.name = "rockchip/rk3399-kobol-helios64.dtb";
```
- Storage choice: ZFS, mdraid, or btrfs. For ZFS:
```
boot.supportedFilesystems = [ "zfs" ];
services.zfs.autoScrub.enable = true;
```
- Network: verify 1GbE and 2.5GbE; consider avoiding 2.5GbE if unstable.
- Fans/UPS: add PWM fan control and UPS monitoring if needed.

## First Install (high level)
1) Prepare boot media (Tow-Boot/U-Boot as needed).
2) From builder/controller, use `nixos-anywhere` with `disko` to partition/install.
3) Minimal host config: SSH, networking, device tree, console, storage.
   - This repo provides a starter host at `.#nixosConfigurations.helios64`.
   - Evaluate: `nix eval .#nixosConfigurations.helios64.config.system.build.toplevel`
   - First install (example): `nix run github:numtide/nixos-anywhere -- --flake .#helios64 <ssh-host>`

## Related Docs
- See `docs/HELIOS64_DESIGN.md` for architecture and storage design.
- See `docs/adr/0001-choose-zfs-for-helios64.md` for the ZFS decision.
4) Reboot and verify; then iterate storage/services.

## Storage Layout (examples)
- Single-disk root on SATA, data pool on remaining drives (ZFS/RAID/btrfs).
- Use `disko` to declaratively partition and format; run dry-run before apply.

## Known considerations
- 2.5GbE port stability/performance may vary on some units; test and pin to 1GbE if needed.
