#!/usr/bin/env bats
test_db="pg_evolve_test"

setup () {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE=${PGDATABASE} \
    --network=pg-evolve_default \
    postgres:alpine dropdb --if-exists "${test_db}"

  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE=${PGDATABASE} \
    --network=pg-evolve_default \
    postgres:alpine psql -c "CREATE DATABASE \"${test_db}\" WITH OWNER \"${PGUSER}\"";
}

@test "Installing pg-evolve on empty database" {
  docker run --rm \
  -e PGHOST=${PGHOST} \
  -e PGUSER=${PGUSER} \
  -e PGPASSWORD=${PGPASSWORD} \
  -e PGDATABASE="${test_db}" \
  --network=pg-evolve_default \
  pg-evolve:latest

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      postgres:alpine psql -tAF ',' -c '\dt'
  )"
  [ ! -z "$(echo ${result} | grep "pg_evolve_version")" ]
}
