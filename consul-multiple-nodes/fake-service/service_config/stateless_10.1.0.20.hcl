service {
  name = "stateless"
  id = "stateless_10.1.0.20"
  port = 9090

  check {
    id = "stateless_check"
    name = "Check Stateless health"
    http = "http://169.254.2.12:9090/health"
    method = "GET"
    interval = "10s"
    timeout = "1s"
  }

  connect {
    sidecar_service {
      port = 21001

      proxy {
        local_service_address = "127.0.0.1"
        upstreams {
          destination_name = "stateful"
          local_bind_address = "127.0.0.1"
          local_bind_port = 9091
        }
      }
    }
  }
}
