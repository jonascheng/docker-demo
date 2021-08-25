#!/bin/bash

docker exec -it pcs bash -c "echo 12345678 | passwd hacluster --stdin"