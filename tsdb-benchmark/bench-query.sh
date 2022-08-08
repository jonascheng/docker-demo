#!/bin/bash

. ./getopts.sh >&2 >/dev/null

echo === setup ===
. ./setup.sh >&2 >/dev/null

###
echo === insert command ===
docker exec -it tsdb sh -c "cat /tmp/insert-events-generate.sql"

####
echo
echo "=== measure normal table query by last 7 days AND agent_id > 50 ==="
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
time docker exec -it tsdb psql -U postgres -c "SELECT COUNT(1) FROM sample_events WHERE agent_id > 50 AND event_time > now() - INTERVAL '7 days';"
echo === measure normal table query by last 1 days AND group by hour ===
time docker exec -it tsdb psql -U postgres -c "SELECT date_trunc('hour', event_time) as hour, COUNT(1) FROM sample_events WHERE event_time > now() - INTERVAL '1 days' GROUP BY hour ORDER BY hour LIMIT 12;"

####
echo "=== measure hypertable query by last 7 days AND agent_id > 50 ==="
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
time docker exec -it tsdb psql -U postgres -c "SELECT COUNT(1) FROM sample_events WHERE agent_id > 50 AND event_time > now() - INTERVAL '7 days';"
echo === measure normal table query by last 1 days AND group by hour ===
time docker exec -it tsdb psql -U postgres -c "SELECT date_trunc('hour', event_time) as hour, COUNT(1) FROM sample_events WHERE event_time > now() - INTERVAL '1 days' GROUP BY hour ORDER BY hour LIMIT 12;"

####
. ./teardown.sh