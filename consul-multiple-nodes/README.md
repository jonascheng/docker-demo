## Overview

Deploy a Consul datacenter, and an application stack with mimic stateful service. These resources will be used to provide complete service mesh capabilities.

## Prerequisites

- Vagrant
- VirtualBox
- Linux or OSX

## Deployment procedure

1. Clone [docker-demo](https://github.com/jonascheng/docker-demo) repository.
2. Navigate to this directory.
3. `vagrant up` to provision three servers, which are `server1`, `server2` and `server3` respectively.
4. Execute the following commands in three servers

```console
$> vagrant ssh server1
vagrant@server1:~$ cd /vagrant
vagrant@server1:/vagrant$ ./up.sh
```

## Testing procedure

1. Navigate to [http://10.1.0.10:8500/ui/dc1/services](http://10.1.0.10:8500/ui/dc1/services)
2. Notice the services being monitored by Consul.
3. Navigate to [http://10.1.0.10:8080/ui](http://10.1.0.10:8080/ui) and refresh the page to generate traffic.
4. Navigate to [http://10.1.0.10:16686/search](http://10.1.0.10:16686/search) and trace the traffic.

## Additional information

- [https://learn.hashicorp.com/collections/consul/docker](https://learn.hashicorp.com/collections/consul/docker)
- [https://learn.hashicorp.com/tutorials/consul/monitor-datacenter-health](https://learn.hashicorp.com/tutorials/consul/monitor-datacenter-health)
- [https://learn.hashicorp.com/tutorials/consul/kubernetes-layer7-observability](https://learn.hashicorp.com/tutorials/consul/kubernetes-layer7-observability)
- [https://www.consul.io/docs/agent/telemetry](https://www.consul.io/docs/agent/telemetry)
- [https://learn.hashicorp.com/tutorials/consul/monitor-datacenter-health](https://learn.hashicorp.com/tutorials/consul/monitor-datacenter-health)

## Application reference

This demo consists of three services Ingress (HTTP), Stateless (HTTP), and Stateful (gRPC)  which are configured to communicate using Consul Service Mesh.

```
ingress (HTTP) --
                  stateless (HTTP) --
                                      stateful (gRPC)
```

Tracing has been configured for both the application instances and Envoy proxy using the Zipkin protocol, the spans
will be collected by the bundled Jaeger instance.

![](images/fake-ui.png)
