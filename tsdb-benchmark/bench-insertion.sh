#!/bin/bash

####
# shell command line
usage="$(basename "$0") [-h] [-d n] -- benchmark data insertion

where:
    -h  show this help text
    -s  set the seed value (default: 42)"

interval_days=30
while getopts ':hd:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    d) interval_days=$OPTARG
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

#####
docker-compose up -d

echo pause to wait for tsdb ready
sleep 5

####
# token replacement
shell_cmd="sed 's/__INSERT_INTERVAL_DAYS__/${interval_days}/g' /sql/insert-events-generate.sql | tee /tmp/insert-events-generate.sql"
docker exec -it tsdb sh -c "${shell_cmd}"

docker exec -it tsdb psql -U postgres -f /sql/clean.sql
docker exec -it tsdb psql -U postgres -f /sql/insert-agents-generate.sql

# create raw sql with insert commands
docker exec -it tsdb psql -U postgres -f /sql/create-events-normaltable.sql
docker exec -it tsdb psql -U postgres -f /tmp/insert-events-generate.sql
# for pg11
# docker exec -it tsdb pg_dump --table sample_events --data-only --inserts -f /tmp/insert-events.sql -U postgres postgres
# for pg12
docker exec -it tsdb pg_dump --table sample_events --data-only --inserts --rows-per-insert=100 -f /tmp/insert-events.sql -U postgres postgres

#####
echo measure normal table insertion
docker exec -it tsdb psql -U postgres -f "/sql/create-events-normaltable.sql"
time docker exec -it tsdb psql -U postgres -f "/tmp/insert-events.sql" >&2 >/dev/null

#####
echo measure hypertable insertion
docker exec -it tsdb psql -U postgres -f /sql/create-events-hypertable.sql
time docker exec -it tsdb psql -U postgres -f /tmp/insert-events.sql >&2 >/dev/null

docker-compose down
