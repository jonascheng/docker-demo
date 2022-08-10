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
echo === insert data with chunk_time_interval: ${chunk_time_interval} days ===
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql

####
echo === check up chunks information before compression ===
docker exec -it tsdb psql -U postgres -c "SELECT chunk_name, table_bytes, index_bytes, toast_bytes, total_bytes FROM chunks_detailed_size('sample_events') ORDER BY chunk_name;"

####
echo === enable compression ===
docker exec -it tsdb psql -U postgres -c "ALTER TABLE sample_events SET (timescaledb.compress);"
echo === add compression policy to compress chunks that are older than 3 days
docker exec -it tsdb psql -U postgres -c "SELECT add_compression_policy('sample_events', INTERVAL '3 days');"

####
echo === find all jobs related to compression policies ===
docker exec -it tsdb psql -U postgres -c "SELECT application_name, schedule_interval, hypertable_name FROM timescaledb_information.jobs WHERE hypertable_name = 'sample_events';"

####
echo === alter schedule interval to 5 seconds ===
docker exec -it tsdb psql -U postgres -c "SELECT alter_job(job_id, schedule_interval => INTERVAL '5 seconds') FROM timescaledb_information.jobs WHERE hypertable_name = 'sample_events';"

####
echo === pause to wait for compression policy take place ===
sleep 10

# check up chunks information
echo you may notice that chunks _hyper_1_1_chunk - _hyper_1_4_chunk were compressed
docker exec -it tsdb psql -U postgres -c "SELECT chunk_name, table_bytes, index_bytes, toast_bytes, total_bytes FROM chunks_detailed_size('sample_events') ORDER BY chunk_name;"

. ./teardown.sh