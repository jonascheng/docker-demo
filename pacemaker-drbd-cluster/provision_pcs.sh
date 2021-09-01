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

docker exec -it pcs bash -c "drbdadm primary --force mydrbd"
docker exec -it pcs bash -c "mkfs.ext4 /dev/drbd0"

docker exec -it pcs bash -c "pcs cluster start --all"
docker exec -it pcs bash -c "pcs cluster enable --all"

docker exec -it pcs bash -c "pcs property set no-quorum-policy=ignore"
# docker exec -it pcs bash -c "pcs resource defaults update migration-threshold=1"
docker exec -it pcs bash -c "pcs resource defaults update resource-stickiness=100"

# vip
docker exec -it pcs bash -c "pcs resource create virtual-ip ocf:heartbeat:IPaddr2 ip=10.1.0.30 cidr_netmask=24 op monitor interval=30s --group mygroup"

# filesystem
docker exec -it pcs bash -c "pcs resource create drbdfs ocf:heartbeat:Filesystem device=/dev/drbd0 directory=/mnt/drbd fstype=ext4 --group mygroup"

# drbd
docker exec -it pcs bash -c "pcs resource create mydrbd ocf:linbit:drbd drbd_resource=mydrbd promotable promoted-max=1 promoted-node-max=1 clone-max=2 clone-node-max=1 notify=true"
#docker exec -it pcs bash -c "pcs resource create mydrbd ocf:linbit:drbd drbd_resource=mydrbd --group mygroup"
#docker exec -it pcs bash -c "pcs resource update mydrbd ocf:linbit:drbd op monitor role=Master interval=50s timeout=30s"
#docker exec -it pcs bash -c "pcs resource update mydrbd ocf:linbit:drbd op monitor role=Slave interval=60s timeout=30s"
#docker exec -it pcs bash -c "pcs resource update mydrbd ocf:linbit:drbd op start timeout=240s"
#docker exec -it pcs bash -c "pcs resource update mydrbd ocf:linbit:drbd op stop timeout=100s"
#docker exec -it pcs bash -c "pcs resource promotable mydrbd meta master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true"

docker exec -it pcs bash -c "pcs constraint colocation add drbdfs with master mydrbd-clone"
docker exec -it pcs bash -c "pcs constraint order promote mydrbd-clone then start drbdfs"

docker exec -it pcs bash -c "pcs property set stonith-enabled=false"

docker exec -it pcs bash -c "pcs status"
docker exec -it pcs bash -c "pcs cluster status"
