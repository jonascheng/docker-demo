#!/bin/bash

docker-compose up -d

echo pause to wait for tsdb ready
sleep 5

docker exec -it tsdb psql -U postgres -f "/sql/clean.sql"
docker exec -it tsdb psql -U postgres -f "/sql/insert-agents.sql"

# create raw data with insert commands
docker exec -it tsdb psql -U postgres -f "/sql/create-events-normaltable.sql"
docker exec -it tsdb psql -U postgres -f "/sql/insert-events.sql"
docker exec -it tsdb pg_dump --table sample_events --data-only --inserts -f /tmp/insert-events.sql -U postgres postgres

#####
echo measure normal table insertion
docker exec -it tsdb psql -U postgres -f "/sql/create-events-normaltable.sql"
time docker exec -it tsdb psql -U postgres -f "/tmp/insert-events.sql" >&2 >/dev/null

#####
echo measure hypertable insertion
docker exec -it tsdb psql -U postgres -f "/sql/create-events-hypertable.sql"
time docker exec -it tsdb psql -U postgres -f "/tmp/insert-events.sql" >&2 >/dev/null

docker-compose down
