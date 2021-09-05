1. Launch MongoDB container in background

```console
docker-compose up -d
```

2. (Optional) Check connectivity among 3 containers

Connect to `rs1` container

```console
docker-compose exec rs1 bash
```

Make `rs1` can connect to the rest of two containers.

```console
mongosh mongodb://rs1:27041 --eval "print('ok')"
mongosh mongodb://rs2:27042 --eval "print('ok')"
mongosh mongodb://rs3:27043 --eval "print('ok')"
```

3. Set up replica set

Connect to `rs1` container

```console
docker-compose exec rs1 bash
```

Set up replica set configuration

```console
mongosh mongodb://rs1:27041

cfg = {
  "_id": "RS",
  "members": [{
      "_id": 0,
      "host": "rs1:27041"
    },
    {
      "_id": 1,
      "host": "rs2:27042"
    },
    {
      "_id": 2,
      "host": "rs3:27043"
    }
  ]
};

rs.initiate(cfg);
```

The output should indicate the success.

```console
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1630834150, i: 1 }),
    signature: {
      hash: Binary(Buffer.from("0000000000000000000000000000000000000000", "hex"), 0),
      keyId: Long("0")
    }
  },
  operationTime: Timestamp({ t: 1630834150, i: 1 })
}
```

4. Check replica set status

With this command to know which is primary and which are secondary.

```console
rs.status().members.map(m => `${m.name}(${m.stateStr})`).join('\n')
```

5. Connect to MongoDB replica set

```console
mongosh mongodb://s1:27041,rs2:27042,rs3:27043/?replicaSet=RS
```

Populate whatever content

```console
db.col.insertOne({text: 'hi'})
```
