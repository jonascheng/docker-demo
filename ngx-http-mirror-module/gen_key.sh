#!/bin/bash
OUT=cert

if [ ! -d "$OUT" ]; then
  mkdir -p $OUT
fi

openssl req -x509 -new -nodes -sha256 -utf8 -days 3650 -newkey rsa:2048 -keyout $OUT/server.key -out $OUT/server.crt -config ssl.conf
