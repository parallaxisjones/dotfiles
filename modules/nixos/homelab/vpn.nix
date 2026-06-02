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
      # Free Proton account: restrict to free-tier servers (FREE_ONLY) and keep
      # port forwarding off — free Proton does not support WireGuard PF.
      FREE_ONLY = "on";
      VPN_PORT_FORWARDING = "off";
      # Free servers exist in the US (the downloaded config was US-FREE); this
      # pairs with FREE_ONLY. Upgrade to a paid plan to use other countries + PF.
      SERVER_COUNTRIES = "United States";
      # Client interface address from the Proton config's [Interface] Address line
      # (IPv4 only — avoids IPv6 routing issues inside Docker). Without this,
      # the tunnel handshakes but no traffic routes (the i/o-timeout loop we hit).
      # If a regenerated config assigns a different address, update this value.
      WIREGUARD_ADDRESSES = "10.2.0.2/32";
      TZ = config.time.timeZone;
    };

    # Holds WIREGUARD_PRIVATE_KEY=... (decrypted by agenix at activation).
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
