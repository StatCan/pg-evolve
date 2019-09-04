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
    postgres:alpine psql -c "CREATE DATABASE \"${test_db}\" WITH OWNER \"${PGUSER}\"" > /dev/null
}

@test "Installing pg-evolve on empty database succeeds" {
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

@test "Installing pg-evolve on non-empty database created with pg-evolve succeeds" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/2:/opt/pg-evolve/evolutions \
    pg-evolve:latest

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
        postgres:alpine psql -tAF ',' -c '\dt' || true
    )"
    [ ! -z "$(echo ${result} | grep "pg_evolve_version")" ]
}

@test "Installing pg-evolve on non-empty database not created with pg-evolve fails" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    postgres:alpine psql -c "CREATE TABLE test (id serial PRIMARY KEY);" > /dev/null

  result1="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      pg-evolve:latest || true
  )"

  result2="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      postgres:alpine psql -tAF ',' -c '\dt'
  )"

  [ ! -z "$(echo ${result1} | grep "ERROR: Database was not created with pg-evolve! Aborting")" ] \
  && [ -z "$(echo ${result2} | grep "pg_evolve_version")"  ]
}
