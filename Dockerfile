FROM docker.io/library/ubuntu:20.04

ARG PKGURL=https://dl.ui.com/unifi/10.1.89/unifi_sysvinit_all.deb

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
      dirmngr \
      gpg \
      gpg-agent \
      wget \
  && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null \
  && echo 'deb https://packages.adoptium.net/artifactory/deb focal main' | tee /etc/apt/sources.list.d/adoptium.list \
  && wget -qO - https://pgp.mongodb.com/server-4.4.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/mongodb-4.4.gpg > /dev/null \
  && echo "deb https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl \
      tzdata \
      binutils \
      ca-certificates-java \
      libcap2 \
      logrotate \
      mongodb-org \
      temurin-25-jre \
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
