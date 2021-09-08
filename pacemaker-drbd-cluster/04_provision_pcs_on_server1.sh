#!/bin/bash

if [[ -z "${OS_RELEASE}" && -f .env ]]
then
  export $(cat .env | xargs)
fi

echo ${OS_RELEASE}
case ${OS_RELEASE} in
  centos7 )
    sudo pcs cluster auth -u hacluster -p 12345678 10.1.0.10 10.1.0.20
    sudo pcs cluster setup --name mycluster 10.1.0.10 10.1.0.20
    ;;
  centos8 )
    sudo pcs host -u hacluster -p 12345678 auth 10.1.0.10 10.1.0.20
    sudo pcs cluster setup mycluster 10.1.0.10 10.1.0.20
    ;;
  * )
    sudo pcs host -u hacluster -p 12345678 auth 10.1.0.10 10.1.0.20
    sudo pcs cluster setup mycluster 10.1.0.10 10.1.0.20
    ;;
esac

sudo drbdadm primary --force mydrbd
sudo mkfs.ext4 /dev/drbd0

sudo pcs cluster start --all
sudo pcs cluster enable --all

sudo pcs property set no-quorum-policy=ignore
sudo pcs resource defaults update resource-stickiness=100

# vip
sudo pcs resource create virtual-ip ocf:heartbeat:IPaddr2 ip=10.1.0.40 cidr_netmask=24 op monitor interval=30s --group mygroup

# filesystem
sudo pcs resource create drbdfs ocf:heartbeat:Filesystem device=/dev/drbd0 directory=/mnt/drbd fstype=ext4 --group mygroup

# drbd
sudo pcs resource create mydrbd ocf:linbit:drbd drbd_resource=mydrbd promotable promoted-max=1 promoted-node-max=1 clone-max=2 clone-node-max=1 notify=true
#sudo pcs resource create mydrbd ocf:linbit:drbd drbd_resource=mydrbd --group mygroup
#sudo pcs resource update mydrbd ocf:linbit:drbd op monitor role=Master interval=50s timeout=30s
#sudo pcs resource update mydrbd ocf:linbit:drbd op monitor role=Slave interval=60s timeout=30s
#sudo pcs resource update mydrbd ocf:linbit:drbd op start timeout=240s
#sudo pcs resource update mydrbd ocf:linbit:drbd op stop timeout=100s
#sudo pcs resource promotable mydrbd meta master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true

sudo pcs constraint colocation add drbdfs with master mydrbd-clone
sudo pcs constraint order promote mydrbd-clone then start drbdfs

# add quorum device
# sudo pcs quorum device add model net host=10.1.0.30 algorithm=ffsplit

sudo pcs property set stonith-enabled=false

sudo pcs status
sudo pcs cluster status
