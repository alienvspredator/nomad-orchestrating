job "cockroachdb" {
  datacenters = ["dc1"]
  type        = "service"

  group "cockroach-master" {
    count = 1

    ephemeral_disk {
      migrate = true
      size = 1500
      sticky = true
    }

    network {
      mode = "bridge"

      port "tcp" {
        to     = 26257
        static = 26257
      }
      port "http" {
        to     = 8080
        static = 8080
      }
    }

    service {
      name = "cockroachdb"
      port = "tcp"

      connect {
        sidecar_service {}
      }
    }

    task "cockroach-node" {
      driver = "docker"

      config {
        image = "cockroachdb/cockroach:v20.1.5"

        args = [
          "start",
          "--insecure",
          "--listen-addr=0.0.0.0",
          "--store=node-master-${NOMAD_ALLOC_INDEX}",
          "--join=$COCKROACH_JOIN"
        ]
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      template {
        data = <<EOH
COCKROACH_JOIN={{ range $index, $cockroach := service "cockroach" }}{{ if eq $index 0 }}{{ $cockroach.Address }}:{{ $cockroach.Port }}{{ else}},{{ $cockroach.Address }}:{{ $cockroach.Port }}{{ end }}{{ end }}
EOH

        destination = "local/config.env"
        change_mode = "noop"
        env         = true
      }
    }
  }

  group "cockroachdb" {
    count = 2
    ephemeral_disk {
      migrate = true
      size = 1500
      sticky = true
    }

    network {
      port "tcp" {}
      port "http" {}
    }

    service {
      name = "cockroachdb"
      port = "tcp"
    }

    task "cockroachdb" {
      driver = "docker"

      config {
        image = "cockroachdb/cockroach:v20.1.5"

        args = [
          "start",
          "--insecure",
          "--listen-addr=0.0.0.0",
          "--store=node-${NOMAD_ALLOC_INDEX}",
          "--port=${NOMAD_PORT_tcp}",
          "--http-port=${NOMAD_PORT_http}",
          "--join=$COCKROACH_JOIN"
        ]
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      template {
        data = <<EOH
COCKROACH_JOIN={{ range $index, $cockroach := service "master.cockroach" }}{{ if eq $index 0 }}{{ $cockroach.Address }}:{{ $cockroach.Port }}{{ else}},{{ $cockroach.Address }}:{{ $cockroach.Port }}{{ end }}{{ end }}
EOH

        destination = "local/config.env"
        env         = true
      }
    }
  }
}
