FROM docker.io/library/ubuntu:20.04

LABEL maintainer="Jacob Alberty <jacob.alberty@foundigital.com>"

ARG DEBIAN_FRONTEND=noninteractive

ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/unifi/data \
    LOGDIR=/unifi/log \
    RUNDIR=/unifi/run \
    CERTDIR=/unifi/cert \
    RUNAS_UID0=true \
    UNIFI_GID=999 \
    UNIFI_UID=999

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      curl \
      dirmngr \
      gpg \
      gpg-agent \
      tzdata \
      gosu \
      binutils \
      ca-certificates-java \
      libcap2 \
      logrotate \
      mongodb-server \
      openjdk-17-jre-headless \
  && echo 'deb [arch=amd64,arm64] https://www.ui.com/downloads/unifi/debian stable ubiquiti' | tee /etc/apt/sources.list.d/100-ubnt-unifi.list \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50 \
  && rm -rf /var/lib/apt/lists/*

ARG PKGURL=https://dl.ui.com/unifi/7.5.176/unifi_sysvinit_all.deb

RUN curl --retry 1 -L -o /tmp/unifi.deb "$PKGURL" \
 && apt -y install /tmp/unifi.deb \
 && rm -f /tmp/unifi.deb

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

COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && chmod +x /usr/local/bin/docker-healthcheck.sh 

VOLUME ["/unifi", "${RUNDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp 10001/udp

WORKDIR /unifi

HEALTHCHECK --start-period=5m CMD /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["unifi"]
