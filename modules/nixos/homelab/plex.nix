_:

# Plex Media Server. Runs with primary group `media` for read access to the
# NAS library (/mnt/nas/media). After first deploy, add media libraries in the
# Plex setup wizard (e.g. /mnt/nas/media/movies, /mnt/nas/media/tv) and set
# Settings → Remote Access → Custom server access URLs to
# https://nixos.tail9fed5f.ts.net/plex so Caddy path-prefix routing works.
{
  services.plex = {
    enable = true;
    group = "media";
    openFirewall = true;
  };

  # The plex service user's home is /var/empty (not writable). Mesa/VAAPI tries
  # to create $HOME/.cache for shader caching and fails with "Operation not
  # permitted", causing VAAPI to crash-restart on every transcode. Redirect the
  # cache to /var/lib/plex where plex already has write access.
  systemd.services.plex.environment.XDG_CACHE_HOME = "/var/lib/plex/.cache";

  # ── Hardware (VAAPI) transcoding ──────────────────────────────────────────────
  # Same AMD Radeon (Polaris/GCN4) render node as the old Jellyfin setup.
  # `hardware.graphics.enable` installs Mesa/radeonsi which Plex's bundled ffmpeg
  # discovers automatically. Plex Pass required for hardware transcoding in Plex.
  hardware.graphics.enable = true;

  # Plex must be able to open the render node.
  users.users.plex.extraGroups = [ "render" "video" ];

  # After deploy, in Plex UI: Settings → Transcoder → Enable hardware-accelerated
  # encoding (requires Plex Pass). VA-API device: /dev/dri/renderD128.
}
