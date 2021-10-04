service {
  name = "ingress"
  id = "ingress_10.1.0.30"
  port = 9090

  check {
    id = "ingress_check"
    name = "Check Ingress health"
    http = "http://169.254.2.11:9090/health"
    method = "GET"
    interval = "10s"
    timeout = "1s"
  }

  connect {
    sidecar_service {
      port = 21000

      proxy {
        local_service_address = "127.0.0.1"
        upstreams {
          destination_name = "stateless"
          local_bind_address = "127.0.0.1"
          local_bind_port = 9091
        }
      }
    }
  }
}
