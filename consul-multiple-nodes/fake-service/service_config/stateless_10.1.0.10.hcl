service {
  name = "stateless"
  # services must have unique IDs per node.
  id = "stateless-10.1.0.10"
  address = "10.5.0.4"
  port = 9090

  connect {
    sidecar_service {
      port = 20000

      check {
        name = "Connect Envoy Sidecar"
        tcp = "10.5.0.4:20000"
        interval ="10s"
      }

      proxy {
        upstreams {
          destination_name = "stateful"
          local_bind_address = "127.0.0.1"
          local_bind_port = 9091
        }
      }
    }
  }
}
