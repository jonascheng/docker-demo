#!/bin/bash

. ./getopts.sh >&2 >/dev/null

echo === setup ===
. ./setup.sh >&2 >/dev/null

###
echo === token replacement ===
shell_cmd="sed 's/__INSERT_RANGE_BEGIN_INTERVAL_DAYS__/30/g' /sql/insert-events-generate-range.tmpl.sql | tee /tmp/insert-events-generate-range.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed -i 's/__INSERT_RANGE_END_INTERVAL_DAYS__/0/g' /tmp/insert-events-generate-range.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed 's/__CHUNK_TIME_INTERVAL_DAYS__/7/g' /sql/create-events-hypertable.tmpl.sql | tee /tmp/create-events-hypertable.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null

####
echo === insert range of data with chunk_time_interval: 7 days ===
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate-range.sql

####
echo === check up chunks information before drop_chunks ===
docker exec -it tsdb psql -U postgres -c "SELECT hypertable_name, chunk_name, range_start, range_end FROM timescaledb_information.chunks WHERE hypertable_name = 'sample_events';"

####
echo === purge data with drop_chunks interval: 1 days ===
docker exec -it tsdb psql -U postgres -c "SELECT add_retention_policy('sample_events', INTERVAL '1 days', if_not_exists => true);"

####
echo === find all jobs related to retention policies ===
docker exec -it tsdb psql -U postgres -c "SELECT application_name, schedule_interval, hypertable_name FROM timescaledb_information.jobs WHERE application_name like 'Retention%';"

####
echo === alter schedule interval to 5 seconds ===
docker exec -it tsdb psql -U postgres -c "SELECT alter_job(job_id, schedule_interval => INTERVAL '5 seconds') FROM timescaledb_information.jobs WHERE hypertable_name = 'sample_events';"

####
echo === find all jobs related to retention policies ===
docker exec -it tsdb psql -U postgres -c "SELECT application_name, schedule_interval, hypertable_name FROM timescaledb_information.jobs WHERE application_name like 'Retention%';"

####
echo === pause to wait for retention policy take place ===
sleep 10

# check up chunks information
echo you may notice that chunks _hyper_1_1_chunk - _hyper_1_4_chunk were compressed
docker exec -it tsdb psql -U postgres -c "SELECT hypertable_name, chunk_name, range_start, range_end FROM timescaledb_information.chunks WHERE hypertable_name = 'sample_events';"

####
. ./teardown.sh