{ config, ... }:

# gluetun: a ProtonVPN WireGuard tunnel with a built-in killswitch. qBittorrent
# shares this container's network namespace (see torrent.nix:
# `--network=container:gluetun`), so ALL of qBittorrent's traffic exits through
# the VPN and, if the tunnel drops, qBittorrent has no route out at all. Nothing
# else on the host uses this tunnel.
#
# ── Secret ────────────────────────────────────────────────────────────────────
# The WireGuard private key is NOT in this file. It's an agenix secret
# (modules/nixos/secrets.nix -> protonvpn-wireguard.age in the nix-secrets repo),
# decrypted at activation to an env file whose single line is:
#     WIREGUARD_PRIVATE_KEY=<key from the Proton config's [Interface] PrivateKey>
# gluetun reads it via `environmentFiles` below. If the .age file is missing from
# the pinned `secrets` input, gluetun fails to start.
#
# To rotate the key: regenerate the WireGuard config in the Proton dashboard,
# re-encrypt protonvpn-wireguard.age with the new key, push nix-secrets, then
# `nix flake update secrets` + commit so this host picks it up.
#
# ── Where the rest of the settings come from ───────────────────────────────────
# Everything except the private key is non-secret and lives here as plain env.
# The values map to lines in the Proton WireGuard config you download:
#   [Interface] Address = 10.2.0.2/32  -> WIREGUARD_ADDRESSES (IPv4 part only)
#   [Interface] PrivateKey = ...       -> the agenix secret (above)
# gluetun supplies the server endpoint/peer key itself from its built-in server
# list, so we do NOT copy the [Peer] section — we just tell it which servers to
# pick via SERVER_COUNTRIES / FREE_ONLY.
#
# ── Free vs paid ───────────────────────────────────────────────────────────────
# This host currently runs a FREE Proton account (active block below). Free tier:
#   * only free servers authenticate the key  -> FREE_ONLY = "on"
#   * no WireGuard port forwarding             -> VPN_PORT_FORWARDING = "off"
#   * limited countries (US/NL/JP/… , varies)  -> SERVER_COUNTRIES = "United States"
# Port forwarding being off means worse seeding/connectability (no inbound peers),
# but downloads and outbound connections work fine.
#
# To switch to a PAID plan later: comment out the FREE block, uncomment the PAID
# block, set the server location you want, redeploy, and (if you enable port
# forwarding) wire qBittorrent's listening port to gluetun's forwarded port — see
# the note at the bottom of the PAID block.
#
# Reference: https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/protonvpn.md
let
  qbWebUiPort = 8080;
in
{
  virtualisation.oci-containers.containers.gluetun = {
    # Pin to the v3 major tag. Bump deliberately; gluetun's embedded server list
    # changes between releases (see free-tier caveat below).
    image = "qmcgaw/gluetun:v3";

    environment = {
      # ── Provider (same for free and paid) ──
      VPN_SERVICE_PROVIDER = "protonvpn";
      VPN_TYPE = "wireguard";

      # Client interface address from the Proton config's [Interface] Address line.
      # IPv4 only on purpose — the Docker bridge has no IPv6 by default, and adding
      # the IPv6 address makes gluetun try to configure a route it can't use.
      # WITHOUT this, the tunnel handshakes but no traffic routes (DNS i/o-timeout
      # loop -> gluetun marks itself unhealthy and rotates servers forever).
      # Update if a regenerated config assigns a different address.
      WIREGUARD_ADDRESSES = "10.2.0.2/32";

      # gluetun's built-in DNS-over-TLS (to Cloudflare, over the tunnel) is one of
      # the first things to fail on a congested free server — it shows up as
      # "lookup <host>: i/o timeout" in the healthcheck and triggers a reconnect
      # loop. Turn DoT off so DNS uses the VPN's resolver instead. (On a paid plan
      # the tunnel is stable enough to flip this back to "on" if you want DoT.)
      DOT = "off";

      # ─────────────────────────────────────────────────────────────────────────
      # FREE tier (ACTIVE). Free Proton WireGuard keys only authenticate against
      # free servers, so we must filter to them; otherwise gluetun picks a paid
      # server, the handshake "completes" silently, and every request times out.
      FREE_ONLY = "on";
      VPN_PORT_FORWARDING = "off"; # not available on free
      # Free servers are slow/oversubscribed; give the tunnel more grace before
      # the healthcheck tears it down and reconnects. Too-aggressive restarts
      # churn the connection and stop qBittorrent from holding peers/DHT.
      HEALTH_VPN_DURATION_INITIAL = "30s";
      # Free servers are concentrated in a few countries (the downloaded config
      # was US-FREE). Keep this to a country that actually has free servers.
      SERVER_COUNTRIES = "United States";
      # ─────────────────────────────────────────────────────────────────────────

      # ── PAID tier (commented out — swap in when you upgrade) ──
      # 1. Comment out the three FREE lines above (FREE_ONLY / VPN_PORT_FORWARDING
      #    / SERVER_COUNTRIES).
      # 2. Uncomment the block below and pick your exit location.
      #
      # # Use any server (drop FREE_ONLY entirely on paid).
      # # Choose ONE location selector — country is simplest:
      # SERVER_COUNTRIES = "Netherlands";   # e.g. NL for good P2P + PF
      # # SERVER_CITIES   = "Amsterdam";
      # # SERVER_HOSTNAMES = "node-nl-01.protonvpn.net"; # pin an exact server
      #
      # # Port forwarding: paid Proton supports it over WireGuard. gluetun will
      # # request a port and expose it on its control server (:8000). This greatly
      # # improves seeding because peers can reach you inbound.
      # VPN_PORT_FORWARDING = "on";
      # VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
      # # gluetun writes the negotiated port here; useful for scripting qBittorrent.
      # VPN_PORT_FORWARDING_STATUS_FILE = "/tmp/gluetun/forwarded_port";
      #
      # # NOTE: the forwarded port is dynamic, so qBittorrent's "listening port"
      # # must be set to whatever gluetun negotiated, or inbound peers won't reach
      # # you. Options once on paid:
      # #   - read /tmp/gluetun/forwarded_port and set it in qBittorrent manually, or
      # #   - add a small sidecar/script that polls gluetun's control API
      # #     (http://127.0.0.1:8000/v1/openvpn/portforwarded) and pushes the port
      # #     into qBittorrent via its WebUI API. (Left as a follow-up.)

      TZ = config.time.timeZone;
    };

    # Single line: WIREGUARD_PRIVATE_KEY=... (decrypted by agenix at activation).
    environmentFiles = [ config.age.secrets."protonvpn-wireguard".path ];

    # gluetun publishes qBittorrent's WebUI (qbit lives in this netns). Bound to
    # localhost so only the Caddy reverse proxy can reach it. On PAID with port
    # forwarding you may also want to publish gluetun's control server to read the
    # forwarded port, e.g. add "127.0.0.1:8000:8000/tcp".
    ports = [ "127.0.0.1:${toString qbWebUiPort}:${toString qbWebUiPort}" ];

    extraOptions = [
      # WireGuard needs NET_ADMIN to bring up the wg interface, and the tun device
      # to create the tunnel. Both are required regardless of tier.
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun"
    ];
  };

  # ── Free-tier server caveat ────────────────────────────────────────────────
  # gluetun ships an embedded server list. A known issue strips free Proton
  # servers from that list on some releases / after the server-data updater runs
  # (https://github.com/qdm12/gluetun/issues/2598). Symptom: instead of the
  # i/o-timeout loop you get "no server found" with FREE_ONLY=on. If that happens,
  # pin a known-good free server with SERVER_HOSTNAMES instead of FREE_ONLY, or
  # move to a paid plan. (We do NOT enable gluetun's periodic updater here, so the
  # baked-in list stays put.)
}
