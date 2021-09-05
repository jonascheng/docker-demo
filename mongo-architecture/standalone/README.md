1. Launch MongoDB container in background

```console
docker-compose up -d
```

2. Access to Mongo Shell

```console
docker-compose exec standalone bash
```

3. Connect to MongoDB

```console
mongosh mongodb://standalone:27017
```
