#!/usr/bin/env bash
set -e

readonly image="$1"

status=

docker run -d --rm --name unifitest "$image"

trap 'docker stop unifitest' SIGHUP SIGINT SIGQUIT SIGTERM

for i in $(seq 1 5); do
  sleep 35
  status=$(docker inspect --format='{{json .State.Health.Status}}' unifitest)
  echo "Status: $status"
  if [ "$status" == \"healthy\" ]; then
    break
  fi
done

if [ "$status" == \"healthy\" ]; then
  exit 0
else
  docker logs unifitest
  exit 1
fi
