1. Bring ELK stack up and running

```console
docker-compose up
```

2. Access the Kibana web UI by opening http://localhost:5601 in a web browser and use the following credentials to log in:

* user: elastic
* password: supersecret

3. Injest data

Now that the stack is running, you can go ahead and inject some log entries. The shipped Logstash configuration allows you to send content via TCP:

```console
# unzip Log.tar.gz
# cd into logs/xxx where contains *.journal
# replace CONTAINER_NAME accordingly
docker run -v `pwd`:/tmp -it jonascheng/tools-kit:f7a3a57 journalctl CONTAINER_NAME=acus_safelock --no-pager -D /tmp/ | nc -c localhost 5055
```

4. Create index

```console
curl -XPOST -D- 'http://localhost:5601/api/saved_objects/index-pattern' \
    -H 'Content-Type: application/json' \
    -H 'kbn-version: 7.16.3' \
    -u elastic:supersecret \
    -d '{"attributes":{"title":"logstash-*","timeFieldName":"@timestamp"}}'
```

## Reference

[Elastic stack (ELK) on Docker](https://github.com/deviantony/docker-elk)
