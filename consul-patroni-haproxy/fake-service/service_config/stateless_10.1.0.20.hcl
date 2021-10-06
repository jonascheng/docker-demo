service {
  name = "stateless"
  id = "stateless_10.1.0.20"
  port = 9090

  connect {
    sidecar_service {
      port = 21001

      proxy {
        local_service_address = "127.0.0.1"
        # destination_type default is service
        upstreams {
          # pgsql.default.dc1.internal.44e57e63-8523-d654-e67f-d093ec5b3e01.consul
          destination_name = "pgsql"
          local_bind_address = "127.0.0.1"
          local_bind_port = 25432
        }
        upstreams {
          # Specifies the type of discovery query to use to find an instance to connect to.
          # Valid values are service or prepared_query. Defaults to service.
          destination_type = "prepared_query"
          # Specifies the name of the service or prepared query to route connect to.
          # The prepared query should be the name or the ID of the prepared query.
          # master.default.dc1.query.44e57e63-8523-d654-e67f-d093ec5b3e01.consul
          # no healthy host for TCP connection pool
          destination_name = "master"
          local_bind_address = "127.0.0.1"
          local_bind_port = 25431
        }
        upstreams {
          destination_type = "prepared_query"
          destination_name = "replica"
          local_bind_address = "127.0.0.1"
          local_bind_port = 25433
        }
      }
    }
  }
}
