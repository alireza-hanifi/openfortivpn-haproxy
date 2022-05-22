#!/bin/bash


# Ensure the ppp device exists
[[ -c /dev/ppp ]] || su-exec root mknod /dev/ppp c 108 0



/usr/bin/glider -listen :8443 &
/usr/bin/openfortivpn &

set -o errexit
set -o nounset

readonly RSYSLOG_PID="/var/run/rsyslogd.pid"

main() {
  start_rsyslogd
  start_lb "$@"
}

start_rsyslogd() {
  rm -f $RSYSLOG_PID
  rsyslogd
}

start_lb() {
  exec haproxy -W -db "$@"
}

main "$@"