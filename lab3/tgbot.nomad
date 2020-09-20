job "tgbot" {
  datacenters = ["dc1"]
  type        = "service"

  group "tgbot" {
    count = 1

    network {
      mode = "bridge"
    }

    service {
      name = "tgbot"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "cockroachdb"
              local_bind_port  = 26257
            }
          }
        }
      }
    }

    task "tgbot" {
      driver = "docker"

      config {
        image = "danyloshevchenko123/tgbot:v1.0.0"
      }

      env {
        TG_TOKEN       = "YOUR_TELEGRAM_TOKEN"
        DB_NAME        = "defaultdb"
        DB_USER        = "root"
        DB_HOST        = "${NOMAD_UPSTREAM_IP_cockroachdb}"
        DB_PORT        = "${NOMAD_UPSTREAM_PORT_cockroachdb}"
        DB_SSLMODE     = "disable"
        SECRET_MANAGER = "IN_MEMORY"
      }
    }
  }
}
