job "cockroachdb" {
  datacenters = ["dc1"]
  type        = "service"

  group "cockroachdb" {
    count = 1
    volume "datadir" {
      type      = "host"
      read_only = false
      source    = "cockroachdb"
    }

    network {
      mode = "bridge"

      port "cockroachdb" {
        static = 26257
        to     = 26257
      }
    }

    service {
      name = "cockroachdb"
      port = "cockroachdb"

      connect {
        sidecar_service {}
      }
    }

    task "cockroachdb" {
      driver = "docker"

      volume_mount {
        volume      = "datadir"
        destination = "/cockroach/cockroach-data"
        read_only   = false
      }

      config {
        image = "cockroachdb/cockroach:v20.1.5"

        args = [
          "start-single-node",
          "--insecure",
          "--listen-addr=0.0.0.0"
        ]

        # network_mode = "host"
        # ports        = ["cockroachdb"]
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
  }
}
