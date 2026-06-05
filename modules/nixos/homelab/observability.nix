{ pkgs, ... }:

# Observability stack: Prometheus (metrics) + Loki (logs) + Grafana (UI) + Tautulli (Plex).
#
# Retention is hard-capped at 14 days everywhere so logs can never accumulate
# and fill the disk. Each component's data dir:
#   Prometheus  /var/lib/prometheus2  (~30–50 MB at 15d retention)
#   Loki        /var/lib/loki         (~100–200 MB at 14d retention)
#   Grafana     /var/lib/grafana      (~20 MB, SQLite dashboards/state)
#   Tautulli    /var/lib/plexpy       (~50–100 MB, Plex history SQLite)
#
# Accessed via Caddy (routes added in proxy.nix) at:
#   https://nixos.tail9fed5f.ts.net/grafana/
#   https://nixos.tail9fed5f.ts.net/tautulli/
#
# Ports (localhost only, not opened in firewall):
#   Grafana    3000
#   Prometheus 9001   (9090 is taken by SABnzbd)
#   Loki       3100
#   Tautulli   8181
{
  # ── Prometheus ────────────────────────────────────────────────────────────────
  services.prometheus = {
    enable = true;
    port = 9001;
    retentionTime = "15d";

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{ targets = [ "localhost:9100" ]; }];
      }
      {
        job_name = "systemd";
        static_configs = [{ targets = [ "localhost:9558" ]; }];
      }
      {
        job_name = "caddy";
        static_configs = [{ targets = [ "localhost:2019" ]; }];
        metrics_path = "/metrics";
      }
      {
        job_name = "sonarr";
        static_configs = [{ targets = [ "localhost:9707" ]; }];
      }
      {
        job_name = "radarr";
        static_configs = [{ targets = [ "localhost:9708" ]; }];
      }
      {
        job_name = "prowlarr";
        static_configs = [{ targets = [ "localhost:9709" ]; }];
      }
    ];

    exporters = {
      node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "cpu" "diskstats" "filesystem" "loadavg" "meminfo"
          "netdev" "systemd" "time" "uname"
        ];
      };
      systemd = {
        enable = true;
        port = 9558;
      };
    };
  };

  # exportarr: one Go binary per *arr app, exposes /metrics for Prometheus.
  # Fill in APIKEY after first deploy — get it from each app's Settings → General.
  systemd.services = {
    exportarr-sonarr = {
      description = "Prometheus exporter for Sonarr";
      wantedBy = [ "multi-user.target" ];
      after = [ "sonarr.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.exportarr}/bin/exportarr sonarr";
        Restart = "on-failure";
        DynamicUser = true;
      };
      environment = {
        PORT = "9707";
        URL = "http://localhost:8989";
        APIKEY = "";
      };
    };

    exportarr-radarr = {
      description = "Prometheus exporter for Radarr";
      wantedBy = [ "multi-user.target" ];
      after = [ "radarr.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.exportarr}/bin/exportarr radarr";
        Restart = "on-failure";
        DynamicUser = true;
      };
      environment = {
        PORT = "9708";
        URL = "http://localhost:7878";
        APIKEY = "";
      };
    };

    exportarr-prowlarr = {
      description = "Prometheus exporter for Prowlarr";
      wantedBy = [ "multi-user.target" ];
      after = [ "prowlarr.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.exportarr}/bin/exportarr prowlarr";
        Restart = "on-failure";
        DynamicUser = true;
      };
      environment = {
        PORT = "9709";
        URL = "http://localhost:9696";
        APIKEY = "";
      };
    };
  };

  # ── Loki (log aggregation) ────────────────────────────────────────────────────
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_port = 3100;
        log_level = "warn";
      };

      common = {
        instance_addr = "127.0.0.1";
        path_prefix = "/var/lib/loki";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };

      schema_config.configs = [{
        from = "2024-01-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];

      limits_config = {
        # Hard cap: delete chunks older than 14 days.
        retention_period = "336h";
        reject_old_samples = true;
        reject_old_samples_max_age = "336h";
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        # Compactor enforces retention_period by actively deleting old chunks.
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
      };

      query_range.cache_results = true;
    };
  };

  # Promtail: ships journald logs → Loki
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };

      positions.filename = "/var/lib/promtail/positions.yaml";

      clients = [{ url = "http://localhost:3100/loki/api/v1/push"; }];

      scrape_configs = [{
        job_name = "journal";
        journal = {
          # Don't backfill more than 14 days of logs on first start.
          max_age = "336h";
          labels = {
            job = "systemd-journal";
            host = "nixos";
          };
        };
        relabel_configs = [
          {
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }
          {
            source_labels = [ "__journal__hostname" ];
            target_label = "hostname";
          }
          {
            source_labels = [ "__journal_priority_keyword" ];
            target_label = "level";
          }
        ];
      }];
    };
  };

  # ── Grafana ───────────────────────────────────────────────────────────────────
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "nixos.tail9fed5f.ts.net";
        root_url = "https://nixos.tail9fed5f.ts.net/grafana/";
        serve_from_sub_path = true;
      };
      security = {
        # Change after first login (you'll be prompted on first visit).
        admin_user = "admin";
        admin_password = "admin";
        secret_key = "homelab-change-me";
      };
      analytics.reporting_enabled = false;
      log.level = "warn";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9001";
          isDefault = true;
          access = "proxy";
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
          access = "proxy";
        }
      ];
    };
  };

  # ── Tautulli (Plex analytics) ─────────────────────────────────────────────────
  services.tautulli = {
    enable = true;
    port = 8181;
    openFirewall = false;
  };
}
