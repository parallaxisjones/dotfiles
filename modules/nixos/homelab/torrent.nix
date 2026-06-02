{ config, ... }:

# qBittorrent, pinned into gluetun's network namespace so every byte it sends
# goes through the VPN (killswitch inherited from gluetun). It has no `ports` of
# its own — the WebUI is published by gluetun (vpn.nix) on 127.0.0.1:8080.
#
# The download tree is bind-mounted at the SAME path inside the container as on
# the host (/var/lib/torrents). That way the path qBittorrent reports to Sonarr/
# Radarr matches what those native services see, so no remote-path-mapping is
# needed. Set qBittorrent's default save path to /var/lib/torrents/complete on
# first run. (qBittorrent has no URL-base support, so Caddy serves it at the site
# root rather than a subpath — see proxy.nix.)
{
  virtualisation.oci-containers.containers.qbittorrent = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    dependsOn = [ "gluetun" ];

    # Share gluetun's netns -> all traffic via the VPN. (Cannot combine with `ports`.)
    extraOptions = [ "--network=container:gluetun" ];

    environment = {
      PUID = "8080"; # qbittorrent service user (storage.nix)
      PGID = "985"; # media group (default.nix)
      TZ = config.time.timeZone;
      UMASK = "002"; # group-writable so the *arr stack can import
      WEBUI_PORT = "8080";
    };

    volumes = [
      "/var/lib/qbittorrent:/config"
      "/var/lib/torrents:/var/lib/torrents"
    ];
  };
}
