FROM golang:1.17.6-alpine3.15 as builder

ARG OPENFORTIVPN_VERSION=v1.17.1
ARG GLIDER_VERSION=v0.15.3

RUN \
  apk add --no-cache \
    autoconf automake build-base ca-certificates curl git openssl-dev ppp && \
  update-ca-certificates && \
  # build openfortivpn
  mkdir -p /usr/src/openfortivpn && \
  curl -sL https://github.com/adrienverge/openfortivpn/archive/${OPENFORTIVPN_VERSION}.tar.gz \
    | tar xz -C /usr/src/openfortivpn --strip-components=1 && \
  cd /usr/src/openfortivpn && \
  ./autogen.sh && \
  ./configure --prefix=/usr --sysconfdir=/etc && \
  make -j$(nproc) && \
  make install && \
  # build glider
  mkdir -p /go/src/github.com/nadoo/glider && \
  curl -sL https://github.com/nadoo/glider/archive/${GLIDER_VERSION}.tar.gz \
    | tar xz -C /go/src/github.com/nadoo/glider --strip-components=1 && \
  cd /go/src/github.com/nadoo/glider && \
  go get -v ./...

FROM haproxy:alpine
USER root

RUN apk add --no-cache ca-certificates openssl ppp curl su-exec bash haproxy rsyslog

RUN set -exo pipefail \
    && mkdir -p /etc/rsyslog.d \
    && touch /var/log/haproxy.log \
    && ln -sf /dev/stdout /var/log/haproxy.log

COPY --from=builder /usr/bin/openfortivpn /go/bin/glider /usr/bin/
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY haproxy-rsyslog.conf /etc/rsyslog.d/haproxy.conf
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["-f", "/etc/haproxy/haproxy.cfg"]

