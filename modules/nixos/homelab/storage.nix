_:

# Local download staging. Active downloads + seeding live on the fast local
# ext4 root; completed media is imported (copied) to the NAS by the *arr stack.
{
  # Fixed-uid service account the qBittorrent container runs as (PUID/PGID in
  # torrent.nix). A fixed uid keeps download ownership stable across rebuilds and
  # avoids depending on the dynamically-allocated uid of the login user.
  users.users.qbittorrent = {
    isSystemUser = true;
    uid = 8080;
    group = "media";
    description = "qBittorrent container service account";
  };

  # setgid (leading 2) so files/dirs created under the staging tree inherit the
  # shared `media` group and the *arr services (also in `media`) can import them.
  systemd.tmpfiles.rules = [
    "d /var/lib/torrents            2775 qbittorrent media -"
    "d /var/lib/torrents/incomplete 2775 qbittorrent media -"
    "d /var/lib/torrents/complete   2775 qbittorrent media -"
    "d /var/lib/qbittorrent         0750 qbittorrent media -"

    "d /var/lib/usenet              2775 sabnzbd     media -"
    "d /var/lib/usenet/incomplete   2775 sabnzbd     media -"
    "d /var/lib/usenet/complete     2775 sabnzbd     media -"
  ];
}
