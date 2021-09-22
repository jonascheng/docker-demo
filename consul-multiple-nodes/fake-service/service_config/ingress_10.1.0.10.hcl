service {
  name = "ingress"
  # id = "ingress-10.1.0.10"
  # address = "10.5.0.3"
  port = 8080

  connect {
    sidecar_service {
      port = 21000

      # check {
      #   name = "Connect Envoy Sidecar"
      #   tcp = "10.5.0.3:20000"
      #   interval ="10s"
      # }

      proxy {
        local_service_address = "169.254.1.1"
        upstreams {
          destination_name = "stateless"
          local_bind_address = "169.254.1.1"
          local_bind_port = 9091
        }
      }
    }
  }
}
