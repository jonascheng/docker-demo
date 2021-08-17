service {
  name = "api"
  port = 9090
  
  connect { 
    sidecar_service {
      port = 20000
      
      check {
        name = "Connect Envoy Sidecar"
        tcp = "127.0.0.1:20000"
        interval ="10s"
      }

      proxy {
      }
    }  
  }
}
