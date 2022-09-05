#!/bin/bash

. ./getopts.sh >&2 >/dev/null

echo === setup ===
. ./setup.sh >&2 >/dev/null

###
echo === create hypertable command ===
docker exec -it tsdb sh -c "cat /tmp/create-events-hypertable.sql"
echo === insert command ===
docker exec -it tsdb sh -c "cat /tmp/insert-events-generate.sql"

####
echo
echo "=== measure normal table delete before 7 days ==="
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -c "SELECT COUNT(1) FROM sample_events WHERE event_time < now() - INTERVAL '7 days';"
time docker exec -it tsdb psql -U postgres -c "DELETE FROM sample_events WHERE event_time < now() - INTERVAL '7 days';"

####
echo "=== measure hypertable delete before 7 days ==="
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -c "SELECT COUNT(1) FROM sample_events WHERE event_time < now() - INTERVAL '7 days';"
time docker exec -it tsdb psql -U postgres -c "DELETE FROM sample_events WHERE event_time < now() - INTERVAL '7 days';"

####
. ./teardown.sh