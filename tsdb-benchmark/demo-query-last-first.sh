#!/bin/bash

. ./getopts.sh >&2 >/dev/null

echo === setup ===
. ./setup.sh >&2 >/dev/null

####
echo === query by last 1 days AND group by 2 hours with time_bucket ===
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -c "SELECT time_bucket('2 hour', event_time) as two_hours, first(event_type, event_time) as first_event_type, last(event_type, event_time) as last_event_type, COUNT(1) FROM sample_events WHERE event_time > now() - INTERVAL '1 days' GROUP BY two_hours ORDER BY two_hours LIMIT 12;"

####
. ./teardown.sh