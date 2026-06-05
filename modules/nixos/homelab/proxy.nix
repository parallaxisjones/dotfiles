{ pkgs, ... }:

# Caddy reverse proxy fronting every service under a single tailnet hostname,
# with real TLS certs issued for the tailnet name. Tailnet-only: nothing here is
# meant to face the public internet.
#
# Routing is path-based under one host (tailnet certs are per-machine, not
# wildcard). The *arr apps and Jellyfin support a configurable URL base, so they
# live under /prowlarr, /sonarr, /radarr, /jellyfin — set each app's base URL to
# match (see the per-service modules). qBittorrent has NO subpath support
# upstream, so it is served at the site root (/).
#
# TLS approach: a oneshot mints/refreshes the cert via `tailscale cert` and Caddy
# serves it from files. This requires MagicDNS + HTTPS certificates enabled in
# the Tailscale admin console (one-time). The caddy-tailscale plugin is a
# hands-off alternative but needs a custom Caddy build (vendor hash), so we use
# the file-based approach here.
let
  host = "nixos.tail9fed5f.ts.net";
  certDir = "/var/lib/caddy/tailscale";
in
{
  systemd = {
    tmpfiles.rules = [
      "d ${certDir} 0750 caddy caddy -"
    ];

    # Fetch/refresh the cert before Caddy starts, and weekly thereafter.
    services.tailscale-cert = {
      description = "Provision tailnet TLS certificate for Caddy";
      after = [ "tailscaled.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      before = [ "caddy.service" ];
      wantedBy = [ "caddy.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "caddy";
        Group = "caddy";
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscale cert \
            --cert-file ${certDir}/${host}.crt \
            --key-file ${certDir}/${host}.key \
            ${host}
        '';
      };
    };

    timers.tailscale-cert = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };

  services = {
    # Permit the caddy user to obtain tailnet certs from the tailscale daemon.
    tailscale.permitCertUid = "caddy";

    caddy = {
      enable = true;
      virtualHosts."${host}" = {
        extraConfig = ''
          tls ${certDir}/${host}.crt ${certDir}/${host}.key

          handle /jellyfin/*  { reverse_proxy 127.0.0.1:8096 }
          handle /prowlarr/* { reverse_proxy 127.0.0.1:9696 }
          handle /sonarr/*   { reverse_proxy 127.0.0.1:8989 }
          handle /radarr/*   { reverse_proxy 127.0.0.1:7878 }
          handle /grafana/*  { reverse_proxy 127.0.0.1:3000 }
          handle /tautulli/* { reverse_proxy 127.0.0.1:8181 }
          # Strip X-Forwarded-For so SABnzbd sees 127.0.0.1 and passes its
          # local-only access check. Tailscale IPs (100.x/CGNAT) are not in
          # SABnzbd's definition of local, so without this the request is denied.
          handle /sabnzbd/* {
            reverse_proxy 127.0.0.1:9090 {
              header_up -X-Forwarded-For
            }
          }

          # qBittorrent has no URL-base support, so it owns the site root.
          handle {
            reverse_proxy 127.0.0.1:8080
          }
        '';
      };
    };
  };

  # NOTE: 443 is already open in the firewall (hosts/nixos/configuration.nix) and
  # tailscale0 is a trusted interface. Caddy binds all interfaces by default, so
  # the proxy is reachable on the LAN too; to make it strictly tailnet-only,
  # bind Caddy to the tailscale IP and drop 443 from allowedTCPPorts (follow-up).
}
