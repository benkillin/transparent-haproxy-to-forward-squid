FROM registry.access.redhat.com/ubi7/ubi:7.7-140

RUN yum -y install haproxy openssl net-tools iputils && \
    mkdir -p /certs && \
    mkdir -p /cache && \
    mkdir -p /cert_db

RUN echo $'#!/bin/bash \n\
    chmod o+w /dev/stdout \n\
    chmod o+w /dev/stderr \n\
    rm -f /var/run/rsyslogd.pid \n\
    rsyslogd -n \n\
    chmod o+w /dev/stdout \n\
    chmod o+w /dev/stderr \n\
    exec "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

RUN ln -sf /dev/stdout /var/log/haproxy.log
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY rsyslog-listen.conf /etc/rsyslog.d/listen.conf

EXPOSE 32222

CMD ["/entrypoint.sh"]

CMD ["/usr/sbin/haproxy", "-f", "/etc/haproxy/haproxy.cfg"]