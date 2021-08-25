## Overview

Deploy a two-node cluster with Pacemaker and Corosync managed by pcs.

## Prerequisites

- Vagrant
- VirtualBox
- Linux or OSX

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

Pcs web ui will be available on the https://localhost:2224/. To log in, you need to set password for the `hacluster` linux user inside of the image:
Then you can use `hacluster` as the login name and your password in the web ui.

You can create cluster in the web ui, or via cli. Every node in the cluster must be running pcs docker container and must have setup password for the hacluster user. Then, on one of the nodes in the cluster run:

```console
[root@server1 /]# pcs cluster auth -u hacluster -p [hapass] 10.1.0.10 10.1.0.20
[root@server1 /]# pcs cluster setup --name mycluster 10.1.0.10 10.1.0.20
# pcs在執行以上命令時會生成/etc/corosync/corosync.conf及修改/var/lib/pacemaker/cib/cib.xml檔案，
# corosync.conf為corosync的配置檔案，cib.xml為pacemaker的配置檔案。
# 這兩個配置檔案是叢集的核心配置，重灌系統時建議做好這兩個配置檔案的備份。
[root@server1 /]# pcs cluster start --all
[root@server1 /]# pcs cluster enable --all
# 在兩個節點的情況下設定以下值
[root@server1 /]# pcs property set no-quorum-policy=ignore
# 叢集故障時候服務遷移
[root@server1 /]# pcs resource defaults migration-threshold=1
```

Create virtual IP:

```console
[root@server1 /]# pcs resource create virtual-ip ocf:heartbeat:IPaddr2 ip=10.1.0.30 cidr_netmask=24 op monitor interval=30s --group mygroup
```

Define docker resource image:

```console
[root@server1 /]#
```

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

## Test procedure

Check pcs status:

```console
[root@server1 /]# pcs status
```

Transit virtual IP to server2 by stopping server1

```console
[root@server1 /]# pcs cluster stop 10.1.0.20
```

Check pcs status again:

```console
[root@server1 /]# pcs status
```


## References

[CENTOS7構建HA叢集](https://www.itread01.com/content/1545727875.html)