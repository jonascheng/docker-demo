service {
  name = "ingress"
  id = "ingress-v1"
#  address = "10.1.0.10"
#  port = 9090

  connect {
    sidecar_service {
      port = 20000

      check {
        name = "Connect Envoy Sidecar"
        tcp = "ingress:20000"
        interval ="10s"
      }

      proxy {
        upstreams {
          destination_name = "stateless"
          local_bind_address = "127.0.0.1"
          local_bind_port = 9091
        }
      }
    }
  }
}
