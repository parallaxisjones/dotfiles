{ user, ... }:

# Homelab service stack: torrenting (gluetun + qBittorrent), the *arr
# automation suite, a Jellyfin media server, and a Caddy reverse proxy that
# exposes everything privately over the tailnet. See docs/ and the plan for the
# overall design; each concern lives in its own file below.
{
  imports = [
    ./storage.nix
    ./vpn.nix
    ./torrent.nix
    ./arr.nix
    ./jellyfin.nix
    ./sabnzbd.nix
    ./proxy.nix
  ];

  users = {
    # Shared group for everything that touches the download-staging dir or the
    # NAS media library. Members get group read/write; setgid dirs (storage.nix)
    # propagate the group so files created by one service are usable by another.
    # Fixed gid so it matches the gid forced on the CIFS media mount (nas-mounts.nix).
    groups.media.gid = 985;

    # Let the primary admin browse/manage media and downloads from a shell.
    users.${user}.extraGroups = [ "media" ];
  };

  # All homelab containers run on the Docker daemon already enabled in
  # hosts/nixos/configuration.nix.
  virtualisation.oci-containers.backend = "docker";
}
