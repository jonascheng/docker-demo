service {
  name = "stateful"
  port = 6379

  check {
    id = "stateful_check"
    name = "Check Stateful health"
    tcp = "169.254.2.13:6379"
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
