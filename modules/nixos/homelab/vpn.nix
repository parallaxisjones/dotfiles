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
# This host runs a PAID Proton account (active block below). Paid tier:
#   * any server authenticates the key   -> no FREE_ONLY filter
#   * WireGuard port forwarding available -> VPN_PORT_FORWARDING = "on"
#   * all countries available             -> SERVER_COUNTRIES = "Netherlands" (good P2P)
# Port forwarding lets inbound peers reach you, which materially improves seeding
# and connectability vs the old free tier.
#
# To revert to FREE later: comment out the PAID block, uncomment the FREE block,
# and redeploy. (The FREE block is preserved below for reference.)
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

      # On paid the tunnel is stable, so we use gluetun's built-in DNS-over-TLS
      # (to Cloudflare, over the tunnel). On the old free tier this had to be off
      # because congested servers made DoT the first thing to fail (i/o-timeout
      # reconnect loop). Flip back to "off" if you ever see DNS instability.
      DOT = "on";

      # ─────────────────────────────────────────────────────────────────────────
      # PAID tier (ACTIVE). Any server authenticates the key, so no FREE_ONLY
      # filter. Choose ONE location selector — country is simplest. NL has good
      # P2P throughput and supports port forwarding.
      SERVER_COUNTRIES = "Netherlands";
      # SERVER_CITIES    = "Amsterdam";
      # SERVER_HOSTNAMES = "node-nl-01.protonvpn.net"; # pin an exact server

      # Port forwarding: paid Proton supports it over WireGuard. gluetun requests
      # a port and exposes it on its control server (:8000). Improves seeding
      # because peers can reach you inbound.
      VPN_PORT_FORWARDING = "on";
      VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
      # gluetun writes the negotiated port here; useful for scripting qBittorrent.
      VPN_PORT_FORWARDING_STATUS_FILE = "/tmp/gluetun/forwarded_port";
      # ─────────────────────────────────────────────────────────────────────────
      #
      # NOTE: the forwarded port is dynamic, so qBittorrent's "listening port"
      # must be set to whatever gluetun negotiated, or inbound peers won't reach
      # you. Options:
      #   - read /tmp/gluetun/forwarded_port and set it in qBittorrent manually, or
      #   - add a small sidecar/script that polls gluetun's control API
      #     (http://127.0.0.1:8000/v1/openvpn/portforwarded) and pushes the port
      #     into qBittorrent via its WebUI API. (Left as a follow-up.)

      # ── FREE tier (commented out — swap back if you ever downgrade) ──
      # 1. Comment out the PAID lines above (SERVER_COUNTRIES / the three
      #    VPN_PORT_FORWARDING* lines), and set DOT = "off".
      # 2. Uncomment the block below.
      #
      # FREE_ONLY = "on";                      # free keys only auth on free servers
      # VPN_PORT_FORWARDING = "off";           # not available on free
      # HEALTH_VPN_DURATION_INITIAL = "30s";   # grace for slow/oversubscribed servers
      # SERVER_COUNTRIES = "United States";    # free servers cluster in a few countries

      TZ = config.time.timeZone;
    };

    # Single line: WIREGUARD_PRIVATE_KEY=... (decrypted by agenix at activation).
    environmentFiles = [ config.age.secrets."protonvpn-wireguard".path ];

    # gluetun publishes qBittorrent's WebUI (qbit lives in this netns). Bound to
    # localhost so only the Caddy reverse proxy can reach it. On PAID with port
    # forwarding you may also want to publish gluetun's control server to read the
    # forwarded port, e.g. add "127.0.0.1:8000:8000/tcp".
    ports = [
      "127.0.0.1:${toString qbWebUiPort}:${toString qbWebUiPort}"
      # gluetun control server — read the negotiated forwarded port via
      # `curl http://127.0.0.1:8000/v1/openvpn/portforwarded`.
      "127.0.0.1:8000:8000/tcp"
    ];

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
