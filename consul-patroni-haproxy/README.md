## Overview

Deploy a Consul datacenter, and an patroni-enabled timescaledb service. These resources will be used to provide complete service mesh and timescaledb cluster capabilities.

## Prerequisites

- Vagrant
- VirtualBox
- Linux or OSX

## Architecture

TBD

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

1. Service has been registered in consul correctly.

```console
# check master IP
vagrant@server1:/vagrant$ dig @169.254.1.1 -p 8600 master.pgsql.service.consul
# check replica IPs
vagrant@server1:/vagrant$ dig @169.254.1.1 -p 8600 replica.pgsql.service.consul
```

2. Connect to one of pgsql node

```console
vagrant@server1:/vagrant$ docker run -it timescale/timescaledb:1.5.1-pg11 sh -c "psql -U postgres -h 10.1.0.10"
```