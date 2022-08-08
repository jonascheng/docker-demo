#!/bin/bash

####
# shell command line
usage="$(basename "$0") [-h] [-d n] -- benchmark data insertion

where:
    -h  show this help text
    -s  set the seed value (default: 42)"

interval_days=7
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
