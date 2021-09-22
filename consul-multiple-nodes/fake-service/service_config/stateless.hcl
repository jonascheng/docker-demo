service {
  name = "stateless"
  # services must have unique IDs per node.
  # id = "stateless-10.1.0.10"
  # address = "10.5.0.4"
  port = 8081

  check {
    id = "stateless_check"
    name = "Check Stateless health"
    http = "http://169.254.1.1:8081/health"
    method = "GET"
    interval = "10s"
    timeout = "1s"
  }

  connect {
    sidecar_service {
      port = 21001

      proxy {
        local_service_address = "169.254.1.1"
        upstreams {
          destination_name = "stateful"
          local_bind_address = "169.254.1.1"
          local_bind_port = 9092
        }
      }
    }
  }
}
