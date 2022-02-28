## Overview

Dkron is a system service that runs scheduled jobs at given intervals or times, just like the cron unix service but distributed in several machines in a cluster.
If a machine fails (the leader), a follower will take over and keep running the scheduled jobs without human intervention. Dkron is Open Source and freely available.

## Prerequisites

- Docker
- Linux or OSX

## Architecture

![](https://img-blog.csdnimg.cn/2019120523004418.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE0ODk4NjEz,size_16,color_FFFFFF,t_70)

## Deployment procedure

1. Clone [docker-demo](https://github.com/jonascheng/docker-demo) repository.
2. Navigate to this directory.
3. Execute the following command to bring up the cluster.

```console
docker-compose up --scale dkron-server=4
```

Check the port mapping using `docker-compose ps` and use the browser to navigate to the Dkron dashboard using one of the ports mapped by compose.

## Mounting a mapped file storage volume

Dkron uses the local filesystem for storing the embedded database to store its own application data and the Raft protocol log. The end result is that your Dkron data will be on disk inside your container and lost if you ever remove the container.

To persist your data outside of the container and make it available for use between container launches we can mount a local path inside our container and set the mounted volume to the dkron boot option `--data-dir`

```console
command: agent --server --log-level=debug --bootstrap-expect=1 --data-dir=/dkron.data
```

## Testing procedure

1. Job registration

You can register JOB if you poke API from HTTP

```console
curl http://localhost:8080/v1/jobs -XPOST -d '{
  "name": "job1",
  "schedule": "@every 10s",
  "timezone": "Europe/Berlin",
  "owner": "Platform Team",
  "owner_email": "platform@example.com",
  "disabled": false,
  "tags": {
    "server": "true:1"
  },
  "metadata": {
    "user": "12345"
  },
  "concurrency": "allow",
  "executor": "shell",
  "executor_config": {
    "command": "date"
  }
}'
```

```console
curl http://localhost:8080/v1/jobs -XPOST -d '{
  "name": "job2",
  "schedule": "@every 10m",
  "timezone": "Europe/Berlin",
  "owner": "Platform Team",
  "owner_email": "platform@example.com",
  "disabled": false,
  "tags": {
    "server": "true:1"
  },
  "metadata": {
    "user": "12345"
  },
  "concurrency": "forbid",
  "executor": "http",
  "executor_config": {
    "method": "GET",
    "url": "https://www.google.com",
    "headers": "[]",
    "body": "",
    "timeout": "30",
    "expectCode": "200",
    "expectBody": "",
    "debug": "true"
  },
  "retries": 1
}'
```

`metadata`: Jobs can have an optional extra property field called metadata that allows to set arbitrary tags to jobs and query the jobs using the API: { "name": "job_name", "command": "/bin/true", "schedule": "@every 2m", "metadata": { "user_id": "12345" } } And then query the API to get only the results needed: $ curl http://localhost:8080/v1/jobs --data-urlencode "metadata[user_id]=12345"`

`concurrency`: Jobs can be configured to allow overlapping executions or forbid them. Concurrency property accepts two option:
  * `allow` (default): Allow concurrent job executions.
  * `forbid`: If the job is already running don’t send the execution, it will skip the executions until the next schedule.
  Example: { "name": "job1", "schedule": "@every 10s", "executor": "shell", "executor_config": { "command": "echo \"Hello from parent\"" }, "concurrency": "forbid" }

## See Also

* [dkron doc](https://dkron.io/cli/dkron_doc/) - Generate Markdown documentation for the Dkron CLI.
* [dkron keygen](https://dkron.io/cli/dkron_keygen/) - Generates a new encryption key
