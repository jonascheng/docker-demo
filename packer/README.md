## Overview

Build virtualbox or AMI image with packer.

## Prerequisites

* The host has to support nested virtualization and enabled.

### Launch GCE on Google Cloud Platform

* Open Cloud Shell and execute the command below:

```console
gcloud compute instances create cicd \
  --enable-nested-virtualization \
  --zone=us-west4-b \
  --machine-type=n1-standard-2 \
  --image-project debian-cloud \
  --image-family=debian-9
```

* Install required packages

```console
sudo apt install -y git make
```

## Deployment procedure

1. Clone [docker-demo](https://github.com/jonascheng/docker-demo) repository.
2. Navigate to this directory.
3. Setup build environment by executing command `make setup`.

## Build image

### Build virtualbox image

```console
make build-box-image
```

### Build AMI image

```console
AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID> AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY> make build-aws-image
```
