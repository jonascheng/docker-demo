#!/bin/bash

. ./getopts.sh >&2 >/dev/null

echo === setup ===
. ./setup.sh >&2 >/dev/null

####
echo === create raw sql with insert commands ===
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
docker exec -it tsdb sh -c "cat /tmp/insert-events-generate.sql"
# for pg11
# docker exec -it tsdb pg_dump --table sample_events --data-only --inserts -f /tmp/insert-events.sql -U postgres postgres
# for pg12
docker exec -it tsdb pg_dump --table sample_events --data-only --inserts --rows-per-insert=100 -f /tmp/insert-events.sql -U postgres postgres

####
echo
echo === measure normal table insertion ===
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql >&2 >/dev/null
time docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
echo === total data inserted ===
docker exec -it tsdb psql -U postgres -c "SELECT count(1) from sample_events;"

####
echo === measure hypertable insertion ===
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
time docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
echo === total data inserted ===
docker exec -it tsdb psql -U postgres -c "SELECT count(1) from sample_events;"

####
. ./teardown.sh