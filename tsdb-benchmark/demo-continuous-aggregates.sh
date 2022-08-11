#!/bin/bash

. ./getopts.sh >&2 >/dev/null

echo === setup ===
. ./setup.sh >&2 >/dev/null

####
echo === token replacement ===
shell_cmd="sed 's/__INSERT_RANGE_BEGIN_INTERVAL_DAYS__/120/g' /sql/insert-events-generate-range.tmpl.sql | tee /tmp/insert-events-generate-range.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed -i 's/__INSERT_RANGE_END_INTERVAL_DAYS__/61/g' /tmp/insert-events-generate-range.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed 's/__CHUNK_TIME_INTERVAL_DAYS__/7/g' /sql/create-events-hypertable.tmpl.sql | tee /tmp/create-events-hypertable.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null

shell_cmd="sed 's/__INSERT_RANGE_BEGIN_INTERVAL_DAYS__/60/g' /sql/insert-events-generate-range.tmpl.sql | tee /tmp/insert-events-generate-range_2.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed -i 's/__INSERT_RANGE_END_INTERVAL_DAYS__/0/g' /tmp/insert-events-generate-range_2.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null

####
echo === insert 1st range of data ===
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate-range.sql

####
echo === create materialized view to aggregate agent id and event type by day ===
docker exec -it tsdb psql -U postgres -c "CREATE MATERIALIZED VIEW event_type_summary_daily WITH (timescaledb.continuous) AS SELECT time_bucket(INTERVAL '1 day', event_time) AS bucket, agent_id, event_type, COUNT(1) FROM sample_events GROUP BY agent_id, event_type, bucket;"
docker exec -it tsdb psql -U postgres -c "SELECT add_continuous_aggregate_policy('event_type_summary_daily', start_offset => INTERVAL '3 month', end_offset => INTERVAL '1 days', schedule_interval => INTERVAL '5 seconds', if_not_exists => true);"

####
echo === insert 2nd range of data ===
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate-range_2.sql

####
echo === pause to wait for aggregate policy take place ===
sleep 10
echo === find all jobs related to aggregate policies ===
docker exec -it tsdb psql -U postgres -c "SELECT application_name, scheduled, schedule_interval, next_start, hypertable_name FROM timescaledb_information.jobs WHERE application_name like '%Continuous Aggregate%';"

####
echo "=== measure top N event_type by last 90 days in legacy aggregates ==="
time docker exec -it tsdb psql -U postgres -c "SELECT event_type, COUNT(1) AS counts FROM sample_events WHERE time_bucket(INTERVAL '1 day', event_time) > now() - INTERVAL '90 days' GROUP BY event_type ORDER BY counts DESC;"
echo "=== measure top N event_type by last 90 days in legacy aggregates ==="
time docker exec -it tsdb psql -U postgres -c "SELECT event_type, SUM(count) AS counts FROM event_type_summary_daily WHERE bucket > now() - INTERVAL '90 days' GROUP BY event_type ORDER BY counts DESC;"

####
echo "=== measure top 5 agent by last 90 days in legacy aggregates ==="
time docker exec -it tsdb psql -U postgres -c "SELECT agent_id, COUNT(1) AS counts FROM sample_events WHERE time_bucket(INTERVAL '1 day', event_time) > now() - INTERVAL '90 days' GROUP BY agent_id ORDER BY counts DESC LIMIT 5;"
echo "=== measure top 5 event_type by last 90 days in legacy aggregates ==="
time docker exec -it tsdb psql -U postgres -c "SELECT agent_id, SUM(count) AS counts FROM event_type_summary_daily WHERE bucket > now() - INTERVAL '90 days' GROUP BY agent_id ORDER BY counts DESC LIMIT 5;"

####
. ./teardown.sh