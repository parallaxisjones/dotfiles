## Build Debugging Runbook

Use this checklist to diagnose failing or hanging builds across Linux (NixOS) and macOS (nix-darwin).

### 0) Dry builds (no activation)

- Linux (this host arch):
  - `nix run .#build-dry`
- Darwin:
  - `nix run .#build-dry`

Pass-through flags: `--option max-jobs 1 --option cores 2 --print-build-logs`.

### 1) Resources and OOM

Check resource pressure:
```bash
nproc; free -h; swapon --show; df -h /
```

Mitigation:
- Serialize build: `--option max-jobs 1 --option builders '' --option cores 2`
- Add zram swap (temporary):
```nix
{ ... }: { zramSwap = { enable = true; memoryPercent = 50; }; }
```

### 2) Nix settings

Show effective settings:
```bash
nix show-config | egrep '^(cores|max-jobs|builders|system-features|substituters|max-silent-time|experimental-features)'
```
- Avoid `big-parallel` on low-memory hosts.
- Prefer small `max-jobs` and set `cores` to 1–2.

### 3) Tail failing derivation logs

From an error message with store path:
```bash
nix log /nix/store/<hash>-<drv>.drv | less -R
```

### 4) Common failures

- Node/Chromedriver: requires newer Node (>= 22). Avoid pinning Node 20 on Linux.
- Python wheels on Darwin: disable tests per overlay if necessary (temporary).

### 5) System logs

```bash
journalctl -k -b --no-pager | tail -n 300      # kernel (this boot)
journalctl -p err -S -2h --no-pager            # recent errors
dmesg -T | egrep -i 'out of memory|oom|killed' # OOM signs
```

### 6) Remote builders

If a laptop is building heavy targets:
- Configure remote builder; verify with:
```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```
Then watch the builder for load/activity.

### 7) Minimal profile

For servers, import `hosts/nixos/profiles/minimal.nix` and limit packages to essentials.

### 8) Reproduce a single package

```bash
nix build nixpkgs#<pkg> --print-build-logs
```

### 9) Last resort

Pin nixpkgs to stable for servers (e.g., 25.05) and advance intentionally.


