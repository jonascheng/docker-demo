FROM linkyard/logrotate

COPY logrotate.conf /etc/logrotate.conf
COPY logrotate.cronjob /etc/.logrotate.cronjob
RUN chmod a+x /etc/.logrotate.cronjob
