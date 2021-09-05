#!/bin/bash

docker exec -it pcs bash -c "drbdadm create-md mydrbd"
docker exec -it pcs bash -c "drbdadm up mydrbd"
docker exec -it pcs bash -c "systemctl start drbd"
docker exec -it pcs bash -c "systemctl enable drbd"
