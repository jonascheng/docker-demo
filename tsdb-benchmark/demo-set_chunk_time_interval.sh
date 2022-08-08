#!/bin/bash

. ./getopts.sh >&2 >/dev/null

echo === setup ===
. ./setup.sh >&2 >/dev/null

####
echo === token replacement ===
shell_cmd="sed 's/__INSERT_RANGE_BEGIN_INTERVAL_DAYS__/20/g' /sql/insert-events-generate-range.tmpl.sql | tee /tmp/insert-events-generate-range.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed -i 's/__INSERT_RANGE_END_INTERVAL_DAYS__/8/g' /tmp/insert-events-generate-range.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed 's/__CHUNK_TIME_INTERVAL_DAYS__/7/g' /sql/create-events-hypertable.tmpl.sql | tee /tmp/create-events-hypertable.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null

shell_cmd="sed 's/__INSERT_RANGE_BEGIN_INTERVAL_DAYS__/7/g' /sql/insert-events-generate-range.tmpl.sql | tee /tmp/insert-events-generate-range_2.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null
shell_cmd="sed -i 's/__INSERT_RANGE_END_INTERVAL_DAYS__/0/g' /tmp/insert-events-generate-range_2.sql"
docker exec -it tsdb sh -c "${shell_cmd}" >&2 >/dev/null

####
echo === insert 1st range of data with chunk_time_interval: 7 days ===
docker exec -it tsdb psql -U postgres -f /tmp/create-events-hypertable.sql >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate-range.sql

####
echo === insert 2nd range of data with chunk_time_interval: 1 days ===
docker exec -it tsdb psql -U postgres -c "SELECT set_chunk_time_interval('sample_events', INTERVAL '1 days');" >&2 >/dev/null
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate-range_2.sql

# check up chunks information
echo you may notice that older chunks were in 7 days interval, but the latest chunks are in 1 days
docker exec -it tsdb psql -U postgres -c "SELECT hypertable_name, chunk_name, range_start, range_end FROM timescaledb_information.chunks WHERE hypertable_name = 'sample_events';"

####
. ./teardown.sh