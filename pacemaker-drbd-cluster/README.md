## Overview

Deploy a two-node cluster with Pacemaker and Corosync managed by pcs. In addition to project [`pacemaker-cluster`](https://github.com/jonascheng/docker-demo/tree/main/pacemaker-cluster), this project also leverage DRBD9 to replicate data volume.

## Prerequisites

- Vagrant
- VirtualBox
- Linux or OSX

## Architecture

* Two VMs with IP 10.1.0.10 and 10.1.0.20 respectively.
* Run pacemaker and corosync as a container `pcs`.
* Manage virtual IP 10.1.0.30 by `pcs`.
* Manage mysql with docker-compose by `pcs`.

## Deployment procedure

Pacemaker in this image is able to manage docker containers on the host - that's why I'm exposing docker socket and binary to the image (don't expose if not needed). Cgroup fs and privileged mode is required by the systemd in the container and `--net=host` is required so the pacemaker is able to manage virtual IP.

```console
$> vagrant up
# in one terminal
$> vagrant ssh server1
vagrant@server1:~$ cd /vagrant/
vagrant@server1:/vagrant$ docker-compose build; docker-compose up -d
vagrant@server1:/vagrant$ docker exec -it pcs bash
[root@server1 /]# echo [hapass] | passwd hacluster --stdin
# in another terminal
$> vagrant ssh server2
vagrant@server2:~$ cd /vagrant/
vagrant@server2:/vagrant$ docker-compose build; docker-compose up -d
vagrant@server2:/vagrant$ docker exec -it pcs bash
[root@server2 /]# echo [hapass] | passwd hacluster --stdin
```

A DRBD configuration `/etc/drbd.conf` has been preset in both nodes, feel free to review.
Then initialize the DRBD resource on both nodes, separately

```
# back to the 1st terminal
[root@server1 /]# drbdadm create-md mydrbd
[root@server1 /]# drbdadm up mydrbd
[root@server1 /]# systemctl start drbd
[root@server1 /]# systemctl enable drbd
# back to the 2nd terminal
[root@server2 /]# drbdadm create-md mydrbd
[root@server2 /]# drbdadm up mydrbd
[root@server2 /]# systemctl start drbd
[root@server2 /]# systemctl enable drbd
```

<!--
# prompt server1 to primay role
# [root@server1 /]# drbdadm primary --force mydrbd
# wait sync'ed status to 100%
# [root@server1 /]# watch -n 0.5 cat /proc/drbd

OutPut from Primary node

```console
version: 8.4.10 (api:1/proto:86-101)
srcversion: 473968AD625BA317874A57E
 0: cs:SyncSource ro:Primary/Secondary ds:UpToDate/Inconsistent C r-----
    ns:2956160 nr:0 dw:0 dr:2956160 al:8 bm:0 lo:0 pe:13 ua:0 ap:0 ep:1 wo:f oos:7530908
        [====>...............] sync'ed: 28.3% (7352/10236)M
        finish: 0:03:42 speed: 33,904 (33,956) K/sec
```

OutPut from Second node as well

```console
version: 8.4.10 (api:1/proto:86-101)
srcversion: 473968AD625BA317874A57E
 0: cs:SyncTarget ro:Secondary/Primary ds:Inconsistent/UpToDate C r-----
    ns:0 nr:3917184 dw:3917184 dr:0 al:8 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:6568220
        [======>.............] sync'ed: 37.4% (6412/10236)M
        finish: 0:03:05 speed: 35,360 (34,060) want: 50,040 K/sec
```

After Finish this. Create filesystem on DRBD device. Like this:

```console
[root@server1 /]# mkfs.ext4 /dev/drbd0
# create mount point for DRBD device on primary node
[root@server1 /]# mount -t ext4 /dev/drbd0 /mnt/drbd
```

Verify DRBD works by dropping any file in /mnt/drbd, after that make Secondary node as Primary node. Run below command on `server1`

```console
[root@server1 /]# umount /mnt/drbd
[root@server1 /]# drbdadm secondary mydrbd
```

After this jump on Secondary machine, i.e `server2`. Create mount point for DRBD device on secondary node. The mount point can be the same or different from `server1`. In my case use the same.

```console
$> vagrant ssh server2
vagrant@server1:/vagrant$ docker-compose build; docker-compose up -d
vagrant@server1:/vagrant$ docker exec -it pcs bash
[root@server2 /]# drbdadm -- --overwrite-data-of-peer primary mydrbd
[root@server2 /]# mount -t ext4 /dev/drbd0 /mnt/drbd
```

Check if the file(s) have been sync'ed to `server2`. -->

Create pcs resources.

```console
# for CentOS8
[root@server1 /]# pcs host -u hacluster -p [hapass] auth 10.1.0.10 10.1.0.20
[root@server1 /]# pcs cluster setup mycluster 10.1.0.10 10.1.0.20

# pcs在執行以上命令時會生成/etc/corosync/corosync.conf及修改/var/lib/pacemaker/cib/cib.xml檔案，
# corosync.conf為corosync的配置檔案，cib.xml為pacemaker的配置檔案。
# 這兩個配置檔案是叢集的核心配置，重灌系統時建議做好這兩個配置檔案的備份。
[root@server1 /]# pcs cluster start --all
[root@server1 /]# pcs cluster enable --all
# 在兩個節點的情況下設定以下值
[root@server1 /]# pcs property set no-quorum-policy=ignore
# 叢集故障時候服務遷移
# [root@server1 /]# pcs resource defaults update migration-threshold=1
```

Pacemaker has the concept of resource stickiness, which controls how strongly a service prefers to stay running where it is to prevent resources from moving after recovery:

```console
[root@server1 /]# pcs resource defaults update resource-stickiness=100
```

Create virtual IP:

```console
[root@server1 /]# pcs resource create virtual-ip ocf:heartbeat:IPaddr2 ip=10.1.0.30 cidr_netmask=24 op monitor interval=30s --group mygroup
```

Create DRBD resources, provide RA of DRBD at present by OCF Classified as linbit, its path is `/usr/lib/ocf/resource.d/linbit/drbd`.
You need to run on two nodes at the same time, but there can only be one node (primary/secondary model) Master, and the other node is Slave; therefore, it's a comparison special cluster resources, its resource type is multi state (Multi-state) clone type, that is, the host node has Master and Slave points, and it requires two nodes when the service starts all in slave state.

```console
[root@server1 /]# pcs resource create mydrbd ocf:linbit:drbd drbd_resource=mydrbd --group mygroup
[root@server1 /]# pcs resource update mydrbd ocf:linbit:drbd op monitor role=Master interval=50s timeout=30s
[root@server1 /]# pcs resource update mydrbd ocf:linbit:drbd op monitor role=Slave interval=60s timeout=30s
[root@server1 /]# pcs resource update mydrbd ocf:linbit:drbd op start timeout=240s
[root@server1 /]# pcs resource update mydrbd ocf:linbit:drbd op stop timeout=100s
[root@server1 /]# pcs resource promotable mydrbd meta master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
```

But as a file system, you need to mount , hold drbd Mount to /data Catalog

```console
[root@server1 /]# pcs resource create drbdfs ocf:heartbeat:Filesystem device=/dev/drbd0 directory=/mnt/drbd fstype=ext4 --group mygroup
```

File system mount `drbdfs` it has to be with Master mydrbd on the same node, must be started first mydrbd then you can mount drbdfs file system, so you have to define resource constraints.

```console
[root@server1 /]# pcs constraint colocation add drbdfs with master mydrbd-clone
[root@server1 /]# pcs constraint order promote mydrbd-clone then drbdfs
```

<!-- Define docker-compose resource:

```console
[root@server1 /]# pcs resource create myapp ocf:heartbeat:docker-compose dirpath=/home/app op monitor interval=60s --group mygroup meta resource-stickiness=10O
``` -->

Disable stonith (this will start the cluster):

```console
[root@server1 /]# pcs property set stonith-enabled=false
```

Check pcs and cluster status:

```console
[root@server1 /]# pcs status
[root@server1 /]# pcs cluster status
```

You can view and modify your cluster in the web ui even when you created it in cli, but you need to add it there first (Add existing).

Enable corosync and pacemaker services to start at boot:

```console
# in server1 container
[root@server1 /]# systemctl enable corosync.service
[root@server1 /]# systemctl enable pacemaker.service
# in server2 container
[root@server2 /]# systemctl enable corosync.service
[root@server2 /]# systemctl enable pacemaker.service
```

## Test procedure

Check pcs status:

```console
[root@server1 /]# pcs status
Cluster name: mycluster
Cluster Summary:
  * Stack: corosync
  * Current DC: 10.1.0.10 (version 2.0.5-9.el8_4.1-ba59be7122) - partition with quorum
  * Last updated: Thu Aug 26 01:52:38 2021
  * Last change:  Thu Aug 26 01:52:35 2021 by root via cibadmin on 10.1.0.10
  * 2 nodes configured
  * 2 resource instances configured

Node List:
  * Online: [ 10.1.0.10 10.1.0.20 ]

Full List of Resources:
  * Resource Group: mygroup:
    * virtual-ip	(ocf::heartbeat:IPaddr2):	 Started 10.1.0.10 # 此條表示 vip 目前在 server1 上執行
    * myapp	(ocf::heartbeat:docker-compose):	 Started 10.1.0.10 # 此條表示 app 目前在 server1 上執行

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Transit virtual IP and app to server2 by stopping server1

```console
$> vagrant halt server1
```

Check pcs status again on server2:

```console
[root@server2 /]# pcs status
Cluster name: mycluster
Cluster Summary:
  * Stack: corosync
  * Current DC: 10.1.0.20 (version 2.0.5-9.el8_4.1-ba59be7122) - partition with quorum
  * Last updated: Wed Aug 25 08:17:22 2021
  * Last change:  Wed Aug 25 08:12:58 2021 by root via cibadmin on 10.1.0.10
  * 2 nodes configured
  * 1 resource instance configured

Node List:
  * Online: [ 10.1.0.20 ]
  * OFFLINE: [ 10.1.0.10 ]

Full List of Resources:
  * Resource Group: mygroup:
    * virtual-ip	(ocf::heartbeat:IPaddr2):	 Started 10.1.0.20 # 此條表示 vip 在 server2 上執行了

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled

     virtual-ip	(ocf::heartbeat:IPaddr2):	Started 10.1.0.20
```

Bring server1 back online

```console
$> vagrant up server1
```

## References

[CENTOS7構建HA叢集](https://www.itread01.com/content/1545727875.html)