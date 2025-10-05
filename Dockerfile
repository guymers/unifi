FROM docker.io/library/ubuntu:20.04

ARG PKGURL=https://dl.ui.com/unifi/9.2.87/unifi_sysvinit_all.deb

ARG DEBIAN_FRONTEND=noninteractive

ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/unifi/data \
    LOGDIR=/unifi/log \
    RUNDIR=/unifi/run \
    CERTDIR=/unifi/cert \
    CERTNAME=cert.pem \
    CERT_PRIVATE_NAME=privkey.pem \
    CERT_IS_CHAIN=false \
    UNIFI_STDOUT=true

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      curl \
      dirmngr \
      gpg \
      gpg-agent \
      tzdata \
      binutils \
      ca-certificates-java \
      libcap2 \
      logrotate \
      mongodb-server \
      openjdk-17-jre-headless \
  && echo 'deb [arch=amd64,arm64] https://www.ui.com/downloads/unifi/debian stable ubiquiti' | tee /etc/apt/sources.list.d/100-ubnt-unifi.list \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50 \
  && rm -rf /var/lib/apt/lists/*

RUN curl --retry 1 -L -o /tmp/unifi.deb "$PKGURL" \
 && apt -y install /tmp/unifi.deb \
 && rm -f /tmp/unifi.deb

COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
RUN chmod 555 /usr/local/bin/docker-entrypoint.sh \
 && chmod 555 /usr/local/bin/docker-healthcheck.sh

RUN set -ex \
 && mkdir -p /unifi \
 && rm -rf ${BASEDIR}/data ${BASEDIR}/logs ${BASEDIR}/run \
 && mkdir -p ${DATADIR} ${LOGDIR} ${RUNDIR} \
 && ln -s ${DATADIR} ${BASEDIR}/data \
 && ln -s ${LOGDIR} ${BASEDIR}/logs \
 && ln -s ${RUNDIR} ${BASEDIR}/run \
 && mkdir -p /var/cert ${CERTDIR} \
 && ln -s ${CERTDIR} /var/cert/unifi \
 && chown unifi:unifi -R /unifi

RUN mkdir -p /usr/local/lib/unifi/init.d/
COPY import_cert /usr/local/lib/unifi/init.d/

USER unifi:unifi

VOLUME ["${DATADIR}", "${LOGDIR}", "${CERTDIR}", "${RUNDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp 10001/udp

WORKDIR /unifi

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["unifi"]

HEALTHCHECK --start-period=5m CMD /usr/local/bin/docker-healthcheck.sh || exit 1
