service {
  name = "stateless"
  port = 9090

  connect {
    sidecar_service {
      port = 21001

      proxy {
        local_service_address = "127.0.0.1"
        upstreams {
          destination_name = "pgsql.master"
          local_bind_address = "127.0.0.1"
          local_bind_port = 25432
        }
        upstreams {
          destination_name = "replica.pgsql"
          local_bind_address = "127.0.0.1"
          local_bind_port = 25433
        }
      }
    }
  }
}
