{ ... }:

# Jellyfin media server. Runs with primary group `media` for read access to the
# NAS library (/mnt/nas/media). Add the library folders in the Jellyfin setup
# wizard (e.g. /mnt/nas/media/movies, /mnt/nas/media/tv) and set the base URL to
# /jellyfin so it works behind the Caddy path prefix.
{
  services.jellyfin = {
    enable = true;
    group = "media";
  };

  # Hardware (VAAPI) transcoding is left OFF until a render node is confirmed on
  # this host: desktop Ryzen chips have no iGPU, though the old desktop config
  # referenced an amdgpu discrete card. CPU transcoding (and direct-play) work
  # without it. To enable once `/dev/dri/renderD128` exists on the box:
  #
  #   hardware.graphics.enable = true;
  #   users.users.jellyfin.extraGroups = [ "render" "video" ];
  #
  # then select VAAPI (/dev/dri/renderD128) in Jellyfin's Playback settings.
}
