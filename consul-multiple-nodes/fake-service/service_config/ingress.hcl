service {
  name = "ingress"
  port = 9090

  check {
    id = "ingress_check"
    name = "Check Ingress health"
    http = "http://10.5.0.5:9090/health"
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
