#!/usr/bin/env bats
test_db="pg_evolve_test"
major=0
minor=3

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

@test "should install on empty database" {
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

@test "should install on non-empty database created with pg-evolve" {
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

@test "should not install on non-empty database not created with pg-evolve" {
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

@test "should error if PGHOST is not set or empty" {
  result="$(
    docker run --rm \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      pg-evolve:latest || true
  )"
  [ "${result}" = "ERROR: \$PGHOST is not defined" ]
}

@test "should error if PGEVOLVE_INSTALL_PATH is not set or empty" {
  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      -e PGEVOLVE_INSTALL_PATH="" \
      --network=pg-evolve_default \
      pg-evolve:latest || true
  )"
  [ "${result}" = "ERROR: \$PGEVOLVE_INSTALL_PATH is not defined" ]
}

@test "should error if PGEVOLVE_EVOLUTIONS_PATH is not set or empty" {
  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      -e PGEVOLVE_EVOLUTIONS_PATH="" \
      --network=pg-evolve_default \
      pg-evolve:latest || true
  )"
  [ "${result}" = "ERROR: \$PGEVOLVE_EVOLUTIONS_PATH is not defined" ]
}

@test "should set the pg-evolve version" {
  expected="0.3"

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
      postgres:alpine psql -tAF '.' -c 'SELECT * FROM pg_evolve_version'
  )"
  [ "${result}" = "${expected}" ]
}

@test "pg_evolve_needs_upgrade should return true for higher minor version" {
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
      postgres:alpine psql -tA -c "SELECT * FROM pg_evolve_needs_upgrade(${major},$((${minor}+1)))"
  )"
  [ "${result}" = "t" ]
}

@test "pg_evolve_needs_upgrade should return false for lower minor version" {
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
      postgres:alpine psql -tA -c "SELECT * FROM pg_evolve_needs_upgrade(${major},$((${minor}-1)))"
  )"
  [ "${result}" = "f" ]
}

@test "pg_evolve_needs_upgrade should return false for an equal version" {
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
      postgres:alpine psql -tA -c "SELECT * FROM pg_evolve_needs_upgrade(${major},${minor})"
  )"
  [ "${result}" = "f" ]
}

@test "pg_evolve_needs_upgrade should return true for a higher version" {
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
      postgres:alpine psql -tA -c "SELECT * FROM pg_evolve_needs_upgrade($((${major}+1)),$((${minor}-1)))"
  )"
  [ "${result}" = "t" ]


  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      postgres:alpine psql -tA -c "SELECT * FROM pg_evolve_needs_upgrade($((${major}+1)),${minor})"
  )"
  [ "${result}" = "t" ]

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      postgres:alpine psql -tA -c "SELECT * FROM pg_evolve_needs_upgrade($((${major}+1)),$((${minor}+1)))"
  )"
  [ "${result}" = "t" ]
}

@test "pg_evolve_applied should add an entry to the pg_evolve_evolutions table" {
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
      postgres:alpine psql -tA -c "SELECT pg_evolve_applied('1_test.sql', '0.0.0', 'ab42898d4ee56d928b2652f582d92adb34c6cd28039167510aec35f3c9b32b55'); SELECT filename, releaseNumber, sha256 FROM pg_evolve_evolutions;"
  )"
  [ "${result}" = "1_test.sql|0.0.0|ab42898d4ee56d928b2652f582d92adb34c6cd28039167510aec35f3c9b32b55" ]
}

@test "pg_evolve_get_evolutions should return filenames and checksums" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    pg-evolve:latest > /dev/null

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      postgres:alpine psql -tAR ',' -c '
      SELECT pg_evolve_applied('"'"'1_test.sql'"'"', '"'"'0.0.0'"'"', '"'"'ab42898d4ee56d928b2652f582d92adb34c6cd28039167510aec35f3c9b32b55'"'"');
      SELECT pg_evolve_applied('"'"'2_test.sql'"'"', '"'"'0.0.0'"'"', '"'"'1f03fe9f6bde5f2b618ad0aaf6ff5933680291d956a63d87293e854cfb412330'"'"');
      SELECT * FROM pg_evolve_get_evolutions();'
  )"
  [ "${result}" = "1_test.sql|ab42898d4ee56d928b2652f582d92adb34c6cd28039167510aec35f3c9b32b55,2_test.sql|1f03fe9f6bde5f2b618ad0aaf6ff5933680291d956a63d87293e854cfb412330" ]
}

@test "should ignore files without the .sql extension" {
  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      pg-evolve:latest
  )"
  [ ! -z "$(echo ${result} | grep "No evolutions found")" ]
}

@test "should not error when no evolutions are found" {
  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      pg-evolve:latest
  )"
  [ ! -z "$(echo ${result} | grep "No evolutions found")" ]
}

@test "should apply evolution" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/2:/opt/pg-evolve/evolutions \
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
    [ ! -z "$(echo ${result} | grep "person")" ]
}

@test "should add the evolution entry to the evolution table" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/2:/opt/pg-evolve/evolutions \
    pg-evolve:latest

    result="$(
      docker run --rm \
        -e PGHOST=${PGHOST} \
        -e PGUSER=${PGUSER} \
        -e PGPASSWORD=${PGPASSWORD} \
        -e PGDATABASE="${test_db}" \
        --network=pg-evolve_default \
        postgres:alpine psql -tA -c 'SELECT filename, releaseNumber, sha256 FROM pg_evolve_evolutions'
    )"
    [ "${result}" = "1_initial.sql||4db0fb1871675cd4adb096a3d40dc94dada4ee595046ad0c7ffb27d3de0bca9a" ]
}

@test "should skip already applied evolutions" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/18/1_initial.sql:/opt/pg-evolve/evolutions/1_initial.sql \
    pg-evolve:latest

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      -v ${HOSTPWD}/test/18:/opt/pg-evolve/evolutions \
      pg-evolve:latest
  )"
  [ ! -z "$(echo ${result} | grep "Evolution 1_initial.sql already applied. Skipping.")" ]
}

@test "should error if the evolution sequence is different" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/18:/opt/pg-evolve/evolutions \
    pg-evolve:latest

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      -v ${HOSTPWD}/test/18/1_initial.sql:/opt/pg-evolve/evolutions/1_initial.sql \
      -v ${HOSTPWD}/test/18/2_test.sql:/opt/pg-evolve/evolutions/2_different.sql \
      pg-evolve:latest || true
  )"
  [ ! -z "$(echo ${result} | grep "ERROR: Local evolution sequence number 2 (2_different.sql) does not match remote evolution: 2_test.sql")" ]
}

@test "should error if an evolution checksum is different" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/18:/opt/pg-evolve/evolutions \
    pg-evolve:latest

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      -v ${HOSTPWD}/test/20/1_initial.sql:/opt/pg-evolve/evolutions/1_initial.sql \
      -v ${HOSTPWD}/test/20/2_test_different:/opt/pg-evolve/evolutions/2_test.sql \
      pg-evolve:latest || true
  )"
  [ ! -z "$(echo ${result} | grep "ERROR: Local evolution sequence number 2 (2_test.sql) does not match remote checksum! Aborting")" ]
}

@test "should ignore different checksum if PGEVOLVE_SKIPCHECKSUMCHECK is set" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/18:/opt/pg-evolve/evolutions \
    pg-evolve:latest

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      -e PGEVOLVE_SKIPCHECKSUMCHECK=true \
      --network=pg-evolve_default \
      -v ${HOSTPWD}/test/20/1_initial.sql:/opt/pg-evolve/evolutions/1_initial.sql \
      -v ${HOSTPWD}/test/20/2_test_different:/opt/pg-evolve/evolutions/2_test.sql \
      pg-evolve:latest || true
  )"
  [ ! -z "$(echo ${result} | grep "Evolution 2_test.sql already applied. Skipping.")" ]
}

@test "should not add an entry for evolutions that fail" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/22:/opt/pg-evolve/evolutions \
    pg-evolve:latest 2> /dev/null || true

    result="$(
      docker run --rm \
        -e PGHOST=${PGHOST} \
        -e PGUSER=${PGUSER} \
        -e PGPASSWORD=${PGPASSWORD} \
        -e PGDATABASE="${test_db}" \
        --network=pg-evolve_default \
        postgres:alpine psql -tA -c 'SELECT filename, releaseNumber, sha256 FROM pg_evolve_evolutions'
    )"
    [ -z "$(echo ${result} | grep '2_test.sql')" ]
}

@test "should apply a good evolution after a bad one failed" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/23/1_initial.sql:/opt/pg-evolve/evolutions/1_initial.sql \
    -v ${HOSTPWD}/test/23/2_test_bad.sql:/opt/pg-evolve/evolutions/2_test.sql \
    pg-evolve:latest 2> /dev/null || true

  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/23/1_initial.sql:/opt/pg-evolve/evolutions/1_initial.sql \
    -v ${HOSTPWD}/test/23/2_test_good.sql:/opt/pg-evolve/evolutions/2_test.sql \
    pg-evolve:latest

    result="$(
      docker run --rm \
        -e PGHOST=${PGHOST} \
        -e PGUSER=${PGUSER} \
        -e PGPASSWORD=${PGPASSWORD} \
        -e PGDATABASE="${test_db}" \
        --network=pg-evolve_default \
        postgres:alpine psql -tA -c 'SELECT filename, releaseNumber, sha256 FROM pg_evolve_evolutions'
    )"
    [ ! -z "$echo ${result} | grep 2_test.sql" ]
}

@test "should revert failing migrations" {
  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/24/1_initial.sql:/opt/pg-evolve/evolutions/1_initial.sql \
    pg-evolve:latest

  docker run --rm \
    -e PGHOST=${PGHOST} \
    -e PGUSER=${PGUSER} \
    -e PGPASSWORD=${PGPASSWORD} \
    -e PGDATABASE="${test_db}" \
    --network=pg-evolve_default \
    -v ${HOSTPWD}/test/24:/opt/pg-evolve/evolutions \
    pg-evolve:latest 2> /dev/null || true

  result="$(
    docker run --rm \
      -e PGHOST=${PGHOST} \
      -e PGUSER=${PGUSER} \
      -e PGPASSWORD=${PGPASSWORD} \
      -e PGDATABASE="${test_db}" \
      --network=pg-evolve_default \
      postgres:alpine psql -A --pset footer -c 'SELECT * FROM person'
  )"
  [ "${result}" = "id|firstname|lastname" ]
}
