#!/bin/bash

. ./getopts.sh

. ./setup.sh

# create raw sql with insert commands
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql
# for pg11
# docker exec -it tsdb pg_dump --table sample_events --data-only --inserts -f /tmp/insert-events.sql -U postgres postgres
# for pg12
docker exec -it tsdb pg_dump --table sample_events --data-only --inserts --rows-per-insert=100 -f /tmp/insert-events.sql -U postgres postgres

#####
echo measure normal table insertion
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql
time docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null

#####
echo measure hypertable insertion
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql
time docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null

. ./teardown.sh