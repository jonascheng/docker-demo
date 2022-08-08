#!/bin/bash

####
# shell command line
usage="$(basename "$0") [-h] [-c n] [-d n] -- benchmark data insertion

where:
    -h  show this help text
    -s  set the seed value (default: 42)"

interval_days=7
chunk_time_interval=1
while getopts ':hc:d:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    c) chunk_time_interval=$OPTARG
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
