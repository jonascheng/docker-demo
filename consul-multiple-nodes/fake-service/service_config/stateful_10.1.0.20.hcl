service {
  name = "stateful"
  # id = "stateful-10.1.0.20"
  # address = "10.5.0.5"
  port = 6379

  connect {
    sidecar_service {
      port = 21002

      # check {
      #   name = "Connect Envoy Sidecar"
      #   tcp = "10.5.0.5:20000"
      #   interval ="10s"
      # }

      proxy {
        local_service_address = "169.254.1.1"
      }
    }
  }
}
