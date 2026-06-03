_:

# Jellyfin media server. Runs with primary group `media` for read access to the
# NAS library (/mnt/nas/media). Add the library folders in the Jellyfin setup
# wizard (e.g. /mnt/nas/media/movies, /mnt/nas/media/tv) and set the base URL to
# /jellyfin so it works behind the Caddy path prefix.
{
  services.jellyfin = {
    enable = true;
    group = "media";
  };

  # ── Hardware (VAAPI) transcoding ──────────────────────────────────────────────
  # This host has a discrete AMD Radeon (Polaris/GCN4, PCI 0c:00.0, device
  # 0x1002:0x67df) exposing a render node at /dev/dri/renderD128. Polaris does
  # H.264 and HEVC (incl. 10-bit) decode+encode in hardware via VAAPI — covers the
  # vast majority of transcodes. (No AV1 hardware decode on Polaris — that needs
  # RDNA2+ — so AV1 sources fall back to CPU.)
  #
  # `hardware.graphics.enable` installs Mesa, whose `radeonsi` driver provides the
  # VAAPI video driver (radeonsi_drv_video.so) and wires up the libva driver path
  # that Jellyfin's bundled ffmpeg discovers automatically.
  hardware.graphics.enable = true;

  # Jellyfin must be able to open the render node. renderD128 is owned root:render;
  # add the service account to `render` (and `video` for the card device). The
  # module's primary group stays `media` (NAS read access) — these are extra.
  users.users.jellyfin.extraGroups = [ "render" "video" ];

  # After deploy, finish in the UI: Dashboard → Playback → Transcoding →
  #   Hardware acceleration = "VA-API", VA-API Device = /dev/dri/renderD128,
  #   enable HEVC/H.264 decoding (leave AV1 off — unsupported on Polaris).
  # Verify the device is usable on the box with:
  #   nix shell nixpkgs#libva-utils -c vainfo --display drm --device /dev/dri/renderD128
}
