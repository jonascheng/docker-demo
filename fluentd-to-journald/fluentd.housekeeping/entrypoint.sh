#!/bin/sh

if [ -d "/etc/periodic/${FLUENTD_HOUSEKEEPING_CRON:-15min}" ]; then
  echo "using /etc/periodic/${FLUENTD_HOUSEKEEPING_CRON:-15min} cron schedule" | ts "${TS_FORMAT}"
  mv /etc/.housekeeping.cronjob "/etc/periodic/${FLUENTD_HOUSEKEEPING_CRON:-15min}/housekeeping"
else
  sed -i '/housekeeping/d' /var/spool/cron/crontabs/root
  echo "assuming \"${FLUENTD_HOUSEKEEPING_CRON:-15min}\" is a cron expression; appending to root's crontab" | ts "${TS_FORMAT}"
  echo "${FLUENTD_HOUSEKEEPING_CRON:-15min} /etc/.housekeeping.cronjob" >> /var/spool/cron/crontabs/root
fi

exec crond -d ${CROND_LOGLEVEL:-7} -f 2>&1 | ts "${TS_FORMAT}"