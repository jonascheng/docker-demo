service {
  name = "pgsql"
  id = "pgsql/patroni_10.1.0.20"
  port = 5432

  check {
    id = "patroni_check"
    name = "Check Stateful health"
    http = "http://169.254.3.1:8008/health"
    method = "GET"
    interval = "10s"
    timeout = "1s"
  }

  connect {
    sidecar_service {
      port = 21002

      proxy {
        local_service_address = "127.0.0.1"
      }
    }
  }
}
