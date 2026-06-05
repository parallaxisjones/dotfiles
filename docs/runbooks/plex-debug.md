# Plex Media Server — Debug Runbook

## Quick reference

| Task | Command |
|------|---------|
| Service status | `systemctl status plex` |
| Live logs | `journalctl -fu plex` |
| Restart | `sudo systemctl restart plex` |
| Playback URL | `http://nixos.tail9fed5f.ts.net:32400` |
| Plex data dir | `/var/lib/plex/Plex Media Server/` |
| Log dir | `/var/lib/plex/Plex Media Server/Logs/` |
| Codec libs | `/var/lib/plex/Plex Media Server/Codecs/` |

---

## Known issues (as of 2026-06-05)

### 1. VAAPI shader cache failure (FIXED in plex.nix)

**Symptom in logs:**
```
Failed to create /var/empty/.cache for shader cache (Operation not permitted)---disabling.
amdgpu.ids: Permission denied
Direct mapping disabled: deriving image does not work: 1 (operation failed).
```

**Root cause:** The `plex` service user's home is `/var/empty` (not writable). Mesa/VAAPI
tries to create `$HOME/.cache` for shader caching and fails, so every transcode spawns a
VAAPI process, it crashes on init, and Plex kills it and retries. The retry usually works
but adds latency and makes complex content (REMUXes, 4K HDR) unreliable.

**Fix applied:** `systemd.services.plex.environment.XDG_CACHE_HOME = "/var/lib/plex/.cache"`
in `modules/nixos/homelab/plex.nix`. Deploy with `sudo nixos-rebuild switch`.

**Verify fix after deploy:**
```
journalctl -u plex --since "5 min ago" | grep -i 'shader\|cache\|amdgpu'
# Should return nothing after a transcode attempt.
```

### 2. amdgpu.ids permission denied (cosmetic, not fixed)

**Symptom:** `Permission denied` on a path inside `/home/runner/_work/plex-conan/...`

**Cause:** Plex ships its own libdrm with a hardcoded build-system path for the GPU
device-ID database. On NixOS the path doesn't exist. VAAPI still works — Plex falls back
to a generic GPU profile. No user-visible impact beyond the log noise.

---

## Debugging a file that won't play

### Step 1 — Check the file's codec
```bash
# Install ffprobe temporarily
nix run nixpkgs#ffmpeg -- -v error -show_entries stream=codec_name,codec_type,channels,width,height,bit_rate -of default /mnt/nas/media/movies/MOVIE/file.mkv
```

| Codec | Notes |
|-------|-------|
| `h264` / `hevc` | Standard — should transcode fine |
| `av1` | No hardware decode on Polaris; heavy CPU transcode |
| `dts` (DTS-HD MA) | Lossless; decoded via `libdca_decoder.so` |
| `truehd` | Lossless Atmos; similar to DTS-HD MA |
| `hdmv_pgs_subtitle` | Blu-ray image subtitles — only affects playback if enabled |
| High `bit_rate` (>25 Mbps) | BluRay REMUX — needs full transcode pipeline |

### Step 2 — Watch live logs while you try to play the file
```bash
journalctl -fu plex | grep -E 'Transcode|error|fail|exit code|Decision'
```

Look for:
- `exit code for process ... is -9 (signal: Killed)` immediately after transcode start → VAAPI init failure (apply shader cache fix)
- `exit code for process ... is 1` → ffmpeg itself failed; look for the transcode command above it in the logs
- `Decision ... Transcode=` → shows what codec decision was made (good for confirming the right path)

### Step 3 — Check hardware transcoding is enabled in Plex UI

Settings → Transcoder → "Use hardware acceleration when available" must be checked (requires Plex Pass, which you have).

### Step 4 — Force a specific quality to test

In the Plex web player, click the settings gear during playback → Quality → choose a specific bitrate (e.g. 8 Mbps). If it plays at lower quality but not "original", the issue is transcode capacity or VAAPI.

---

## File categories and expected behavior

| Format | Direct Play? | Notes |
|--------|-------------|-------|
| H.264 + AAC/AC3, compressed | Yes (some clients) | Easiest; Plex web always transcodes |
| H.264 BluRay REMUX (20–40 Mbps) | No | Needs VAAPI encode; works after shader cache fix |
| HEVC/x265 | No (most clients) | VAAPI needed for performance |
| 4K HDR HEVC REMUX (60–91 Mbps) | No | CPU-intensive; needs VAAPI + tone-mapping |
| AV1 | No | No GPU decode on Polaris; software-only |
| DTS-HD MA / TrueHD audio | No | Always transcodes via `libdca_decoder.so` / EasyAudioEncoder |
| XviD/DivX in AVI | No | Transcodes fine (Plex's ffmpeg handles it) |

---

## Checking VAAPI is healthy

```bash
# Verify render node is accessible by plex user
ls -la /dev/dri/renderD128      # should be crw-rw-rw- or crw-rw---- with plex in render group
groups plex                     # should include: media video render

# Check VAAPI device capabilities
nix shell nixpkgs#libva-utils -c vainfo --display drm --device /dev/dri/renderD128
```

Expected output includes `VAProfileH264High`, `VAProfileHEVCMain`, `VAProfileHEVCMain10`.
Polaris does NOT have `VAProfileAV1Profile0` — AV1 always uses software.

---

## Transcoder statistics logs

Detailed per-segment stats (useful for confirming a file is actually transcoding):
```
/var/lib/plex/Plex Media Server/Logs/Plex Transcoder Statistics.log
```

Each `<Segment>` block shows video/audio chunk sizes and timestamps. If segments stop
appearing for a session shortly after starting, the transcoder failed.

---

## NAS throughput

Media is mounted over Tailscale CIFS from `nasology.tail9fed5f.ts.net`. Tailscale on LAN
negotiates a direct WireGuard connection (not relayed), so throughput should approach
1 Gbps (125 MB/s). The 4K REMUXes at 91 Mbps (11 MB/s) are well within range.

If you suspect NAS slowness:
```bash
dd if=/mnt/nas/media/movies/SOMEFILE.mkv of=/dev/null bs=4M count=256 status=progress
# Expect 50–100 MB/s; anything below 15 MB/s would cause buffering on 4K REMUXes
```
