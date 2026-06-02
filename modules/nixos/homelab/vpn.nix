{ config, ... }:

# gluetun: a ProtonVPN WireGuard tunnel with a built-in killswitch. qBittorrent
# shares this container's network namespace (torrent.nix), so all torrent traffic
# exits through the VPN and, if the tunnel drops, qBittorrent has no route out.
#
# The WireGuard private key is provided by agenix as an env file containing
# `WIREGUARD_PRIVATE_KEY=...` (see modules/nixos/secrets.nix). Add
# protonvpn-wireguard.age to the nix-secrets repo before deploying, or gluetun
# will fail to start.
let
  qbWebUiPort = 8080;
in
{
  virtualisation.oci-containers.containers.gluetun = {
    image = "qmcgaw/gluetun:v3";

    environment = {
      VPN_SERVICE_PROVIDER = "protonvpn";
      VPN_TYPE = "wireguard";
      # ProtonVPN supports port forwarding (paid). Improves seeding/connectability.
      VPN_PORT_FORWARDING = "on";
      VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
      # Exit location. ProtonVPN port forwarding requires a P2P-enabled server;
      # adjust to taste once the tunnel is verified.
      SERVER_COUNTRIES = "Netherlands";
      TZ = config.time.timeZone;
    };

    # Holds WIREGUARD_PRIVATE_KEY=... (and optionally WIREGUARD_ADDRESSES=...).
    environmentFiles = [ config.age.secrets."protonvpn-wireguard".path ];

    # gluetun publishes qBittorrent's WebUI (qbit lives in this netns). Bound to
    # localhost so only the Caddy reverse proxy can reach it.
    ports = [ "127.0.0.1:${toString qbWebUiPort}:${toString qbWebUiPort}" ];

    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun"
    ];
  };
}
