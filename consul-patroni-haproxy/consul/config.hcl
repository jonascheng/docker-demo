# 用來儲存Consul放資料的地方
data_dir = "/consul/data/"

# 更新檢查
disable_update_check = true

# 啟用本地端設定檔腳本檢查
enable_local_script_checks = true

telemetry {
  prometheus_retention_time = "60s"
  disable_hostname = true
}

log_level = "TRACE"

datacenter = "dc1"

# 告訴Consul這個agent要作為server的腳色，如果設為false則為client的腳色
server = true

# 預計要啟動幾個server,若為三台Consul server做HA, 則設定為3
bootstrap_expect = 1
# retry_join  = ["10.1.0.10", "10.1.0.20", "10.1.0.30"]
# retry_interval = "30s"

ui = true

# in production, we should set 169.254.1.1 instead
# client_addr = "169.254.1.1"
client_addr = "0.0.0.0"

ports {
  grpc = 8502
}

# 在Consul cluster中，設定該agent是否允許連線
connect {
  enabled = true
}

enable_central_service_config = true

config_entries {
  bootstrap = [
    {
      kind = "proxy-defaults"
      name = "global"

      config {
      }
    }
  ]
}
