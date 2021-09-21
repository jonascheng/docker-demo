connect {
  enabled = true
}
services {
  name = "client"
  port = 8080
  connect {
    sidecar_service {
      proxy {
        local_service_address = "169.254.1.1"
        upstreams {
          destination_name = "echo"
          local_bind_address = "169.254.1.1"
          local_bind_port = 9191
        }
      }
    }
  }
}
services {
  name = "echo"
  port = 9090
  connect {
    sidecar_service {
      proxy {
        local_service_address = "169.254.1.1"
      }
    }
  }
}