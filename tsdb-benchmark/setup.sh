#!/bin/bash

#####
docker-compose up -d

echo pause to wait for tsdb ready
sleep 5

####
# token replacement
shell_cmd="sed 's/__INSERT_INTERVAL_DAYS__/${interval_days}/g' /sql/insert-events-generate.tmpl.sql | tee /tmp/insert-events-generate.sql"
docker exec -it tsdb sh -c "${shell_cmd}"
shell_cmd="sed 's/__CHUNK_TIME_INTERVAL_DAYS__/${chunk_time_interval}/g' /sql/create-events-hypertable.tmpl.sql | tee /tmp/create-events-hypertable.sql"
docker exec -it tsdb sh -c "${shell_cmd}"

docker exec -it tsdb psql -U postgres -f /sql/clean.sql
docker exec -it tsdb psql -U postgres -f /sql/insert-agents-generate.sql
