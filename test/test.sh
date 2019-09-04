#!/bin/sh
set -e

docker build --quiet -t pg-evolve:latest .;

# wait for db
until
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE=${PGDATABASE} \
    --network=pg-evolve_default \
    postgres:alpine psql -c '\q' 2> /dev/null;
do
  sleep 1;
done

./test/bats.sh
