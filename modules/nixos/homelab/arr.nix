_:

# *arr automation, as native NixOS services (no containers needed — they run on
# the host network and reach qBittorrent's WebUI at 127.0.0.1:8080).
#
#   Prowlarr -> manages indexers, feeds Sonarr/Radarr
#   Sonarr   -> TV
#   Radarr   -> movies
#
# Sonarr/Radarr run with primary group `media` so they can read completed
# downloads under /var/lib/torrents and write imports to /mnt/nas/media (the NAS
# media share is forced to gid=media in nas-mounts.nix). Prowlarr only talks to
# indexers, so it needs no filesystem access and keeps its default DynamicUser.
#
# Post-deploy app config (one-time, in each web UI):
#   - set the URL base to /prowlarr, /sonarr, /radarr to match the Caddy paths
#   - Sonarr/Radarr: add qBittorrent download client at 127.0.0.1:8080
#   - root folders: /mnt/nas/media/tv (Sonarr), /mnt/nas/media/movies (Radarr)
{
  services = {
    prowlarr.enable = true;

    sonarr = {
      enable = true;
      group = "media";
    };

    radarr = {
      enable = true;
      group = "media";
    };
  };
}
