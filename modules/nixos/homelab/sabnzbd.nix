_:

# SABnzbd usenet downloader, native NixOS service.
# Port 9090 avoids colliding with qBittorrent at 8080.
# URL base /sabnzbd matches the Caddy route in proxy.nix.
#
# Post-deploy setup (one-time, in the web UI):
#   - Config → Servers → add your usenet provider (host, port 563, SSL, credentials)
#   - Config → Categories → tv / movies to match Sonarr/Radarr category names
#   - Sonarr/Radarr: add SABnzbd download client at 127.0.0.1:9090, URL base /sabnzbd
{
  services.sabnzbd = {
    enable = true;
    group = "media";

    # system.stateVersion is 24.11, which would default configFile to a legacy
    # path and silently ignore `settings`. Explicitly opt in to the modern path.
    configFile = null;
    # Allow UI-based config changes (server creds, categories, etc.) to persist
    # across rebuilds; NixOS-managed settings (port, dirs) still win on each deploy.
    allowConfigWrite = true;

    settings.misc = {
      port = 9090;
      url_base = "/sabnzbd";
      download_dir = "/var/lib/usenet/incomplete";
      complete_dir = "/var/lib/usenet/complete";
    };
  };
}
