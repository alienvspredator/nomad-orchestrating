log_level = "DEBUG"

data_dir = "/tmp/client1"

name = "client1"

client {
  enabled = true

  servers = ["127.0.0.1:4647"]
  host_volume "cockroachdb" {
    path      = "/opt/client1/cockroachdb/data"
    read_only = false
  }
}

ports {
  http = 5656
}
