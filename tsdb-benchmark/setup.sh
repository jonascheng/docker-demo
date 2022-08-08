#!/bin/bash

#####
docker-compose up -d

echo pause to wait for tsdb ready
sleep 5

####
# token replacement
shell_cmd="sed 's/__INSERT_INTERVAL_DAYS__/${interval_days}/g' /sql/insert-events-generate.sql | tee /tmp/insert-events-generate.sql"
docker exec -it tsdb sh -c "${shell_cmd}"

docker exec -it tsdb psql -U postgres -f /sql/clean.sql
docker exec -it tsdb psql -U postgres -f /sql/insert-agents-generate.sql
