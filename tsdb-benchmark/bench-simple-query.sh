#!/bin/bash

. ./getopts.sh

. ./setup.sh

#####
echo measure normal table query
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql
time docker exec -it tsdb psql -U postgres -c "SELECT COUNT(1) FROM sample_events WHERE event_time > now() - INTERVAL '7 days';"

#####
echo measure hypertable query
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql
time docker exec -it tsdb psql -U postgres -c "SELECT COUNT(1) FROM sample_events WHERE event_time > now() - INTERVAL '7 days';"

. ./teardown.sh