FROM linkyard/logrotate

COPY logrotate.conf /etc/logrotate.conf
RUN chmod 0644 /etc/logrotate.conf
COPY logrotate.cronjob /etc/.logrotate.cronjob
RUN chmod 0755 /etc/.logrotate.cronjob
COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh
