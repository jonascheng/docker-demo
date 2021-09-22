service {
  name = "stateful"
  # id = "stateful-10.1.0.10"
  # address = "10.5.0.5"
  port = 6379

  check {
    id = "stateful_check"
    name = "Check Stateful health"
    tcp = "169.254.1.1:6379"
    interval = "10s"
    timeout = "1s"
  }

  connect {
    sidecar_service {
      port = 21002

      proxy {
        local_service_address = "169.254.1.1"
      }
    }
  }
}
