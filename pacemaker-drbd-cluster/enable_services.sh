#!/bin/bash

# enable corosync and pacemaker services in sequence
docker exec -it pcs bash -c "systemctl enable corosync.service"
docker exec -it pcs bash -c "systemctl enable pacemaker.service"
