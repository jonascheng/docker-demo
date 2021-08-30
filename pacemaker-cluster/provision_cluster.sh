#!/bin/bash

if [[ -z "${OS_RELEASE}" && -f .env ]]
then
  export $(cat .env | xargs)
fi

echo ${OS_RELEASE}
case ${OS_RELEASE} in
  centos7 )
    docker exec -it pcs bash -c "pcs cluster auth -u hacluster -p 12345678 10.1.0.10 10.1.0.20"
    docker exec -it pcs bash -c "pcs cluster setup --name mycluster 10.1.0.10 10.1.0.20"
    ;;
  centos8 )
    docker exec -it pcs bash -c "pcs host -u hacluster -p 12345678 auth 10.1.0.10 10.1.0.20"
    docker exec -it pcs bash -c "pcs cluster setup mycluster 10.1.0.10 10.1.0.20"
    ;;
  * )
    docker exec -it pcs bash -c "pcs host -u hacluster -p 12345678 auth 10.1.0.10 10.1.0.20"
    docker exec -it pcs bash -c "pcs cluster setup mycluster 10.1.0.10 10.1.0.20"
    ;;
esac

docker exec -it pcs bash -c "pcs cluster start --all"
docker exec -it pcs bash -c "pcs cluster enable --all"

docker exec -it pcs bash -c "pcs property set no-quorum-policy=ignore"
# docker exec -it pcs bash -c "pcs resource defaults update migration-threshold=1"
docker exec -it pcs bash -c "pcs resource defaults update resource-stickiness=100"

docker exec -it pcs bash -c "pcs resource create virtual-ip ocf:heartbeat:IPaddr2 ip=10.1.0.30 cidr_netmask=24 op monitor interval=30s --group mygroup"

docker exec -it pcs bash -c "pcs resource create myapp ocf:heartbeat:docker-compose dirpath=/home/app --group mygroup"
docker exec -it pcs bash -c "pcs resource update myapp ocf:heartbeat:docker-compose op monitor interval=60s timeout=10s on-fail=restart"
docker exec -it pcs bash -c "pcs resource update myapp ocf:heartbeat:docker-compose op start interval=0s timeout=240s on-fail=restart"
docker exec -it pcs bash -c "pcs resource update myapp ocf:heartbeat:docker-compose op stop interval=0s timeout=20s on-fail=ignore"

docker exec -it pcs bash -c "pcs property set stonith-enabled=false"

docker exec -it pcs bash -c "pcs status"
docker exec -it pcs bash -c "pcs cluster status"
