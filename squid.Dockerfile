FROM registry.access.redhat.com/ubi7/ubi:7.7-140


RUN yum -y update && \
    yum -y install squid openssl net-tools iputils && \
    mkdir -p /certs && \
    mkdir -p /cache && \
    mkdir -p /cert_db 
    #&& \
    #openssl req -newkey rsa:4096 -nodes -sha256 -keyout /certs/key.pem -x509 -days 365 -out /certs/cert.crt

COPY squid.conf /etc/squid/

RUN chmod o+w /dev/stdout && \
    chmod o+w /dev/stderr && \
    /usr/sbin/squid -N -d1 -z && \
    echo $'#!/bin/bash \n\
    chmod o+w /dev/stdout \n\
    chmod o+w /dev/stderr \n\
    /usr/sbin/squid -N -d1' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 3128

CMD ["/entrypoint.sh"]
