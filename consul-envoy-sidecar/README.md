
Follow this [Consul Connect with Envoy and Docker](https://xsreality.medium.com/consul-connect-with-envoy-and-docker-dc0cf53b8c1a) to prepare the demo.

# Deploying Consul Server

Let’s start the Consul server container with configuration `envoy_demo.hcl`.

```console
docker run -d --name=consul-server --net=host \
  -v `pwd`/envoy_demo.hcl:/etc/consul/envoy_demo.hcl \
  hashicorp/consul:1.8.10 agent -server \
  -config-file /etc/consul/envoy_demo.hcl \
  -grpc-port 8502 \
  -client 169.254.1.1 \
  -bind 10.1.0.10 \
  -bootstrap-expect 1 -ui
```

# Running the Echo service

Next, let’s run the `echo` service.

```console
docker run --rm -d --dns 169.254.1.1 --name echo-service \
  --net=bridge \
  -p 169.254.1.1:9090:9090 \
  abrarov/tcp-echo \
  --port 9090
```

Note the container has been started in Docker `bridge` network. This starts the echo service on port `9090` within the container and maps the port on the host machine on dummy IP and host port `9090`. This ensures that the echo service will not be accessible from any other machine in the network.

# Running the Sidecar proxies

Let’s start the sidecar proxies:

```console
docker run --rm -d --dns 169.254.1.1 --name echo-proxy \
  --network host \
  -e CONSUL_HTTP_ADDR=http://169.254.1.1:8500 \
  -e CONSUL_GRPC_ADDR=169.254.1.1:8502 \
  -e CONNECT_SIDECAR_FOR=echo \
  nicholasjackson/consul-envoy:v1.6.1-v0.10.0 \
  consul connect envoy -admin-bind 127.0.0.1:0 -- -l debug
```

This starts the sidecar proxy for `echo` service with the correct Consul HTTP and gRPC endpoints.

```console
docker run --rm -d --dns 169.254.1.1 --name client-proxy \
  --network host \
  -e CONSUL_HTTP_ADDR=http://169.254.1.1:8500 \
  -e CONSUL_GRPC_ADDR=169.254.1.1:8502 \
  -e CONNECT_SIDECAR_FOR=client \
  nicholasjackson/consul-envoy:v1.6.1-v0.10.0 \
  consul connect envoy -admin-bind 127.0.0.1:0 -- -l debug
```

This starts the sidecar proxy for `client` service.

# Running the Client service

Let’s test the setup by connecting to the proxy upstream port `9191`.

```console
docker run -ti --rm --network host gophernet/netcat 169.254.1.1 9191
```

This confirms that our setup works as described in the HashiCorp guide while also securing the real service endpoints to be not routable from outside the machine.

# References

* [Making Docker and Consul Get Along](https://medium.com/zendesk-engineering/making-docker-and-consul-get-along-5fceda1d52b9)