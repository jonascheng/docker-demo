#!/bin/bash

sudo drbdadm create-md mydrbd
sudo drbdadm up mydrbd
sudo systemctl start drbd
sudo systemctl enable drbd
