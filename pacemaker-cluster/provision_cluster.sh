#!/bin/bash

docker exec -it pcs bash -c "pcs cluster auth -u hacluster -p 12345678 10.1.0.10 10.1.0.20"
docker exec -it pcs bash -c "pcs cluster setup --name mycluster 10.1.0.10 10.1.0.20"

docker exec -it pcs bash -c "pcs cluster start --all"
docker exec -it pcs bash -c "pcs cluster enable --all"

docker exec -it pcs bash -c "pcs property set no-quorum-policy=ignore"
docker exec -it pcs bash -c "pcs resource defaults migration-threshold=1"

docker exec -it pcs bash -c "pcs resource create virtual-ip ocf:heartbeat:IPaddr2 ip=10.1.0.30 cidr_netmask=24 op monitor interval=30s --group mygroup"

docker exec -it pcs bash -c "pcs property set stonith-enabled=false"

docker exec -it pcs bash -c "pcs status"
docker exec -it pcs bash -c "pcs cluster status"
