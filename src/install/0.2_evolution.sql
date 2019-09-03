SET pg_evolve.major TO 0;
SET pg_evolve.minor TO 2;

DO $$
BEGIN
  IF (SELECT pg_evolve_needs_upgrade (
    (SELECT current_setting('pg_evolve.major')::int),
    (SELECT current_setting('pg_evolve.minor')::int)
  ))
  THEN
    CREATE TABLE pg_evolve_evolutions (
      id serial PRIMARY KEY,
      filename varchar(255) NOT NULL,
      applied timestamp NOT NULL,
      releaseNumber varchar(255) NOT NULL
    );

    CREATE FUNCTION pg_evolve_get_evolutions ()
    RETURNS TABLE(
      filename varchar(255)
    )
    AS $get$
    SELECT filename FROM pg_evolve_evolutions;
    $get$ LANGUAGE SQL;

    CREATE FUNCTION pg_evolve_applied (
      filename varchar(255),
      releaseNumber varchar(255)
    )
    RETURNS void
    AS $apply$
    BEGIN
      INSERT INTO pg_evolve_evolutions (filename, releaseNumber, applied)
      VALUES (filename, releaseNumber, NOW());
    END
    $apply$ LANGUAGE plpgsql;

    UPDATE pg_evolve_version
    SET
      major=current_setting('pg_evolve.major')::int,
      minor=current_setting('pg_evolve.minor')::int;
  END IF;
END;
$$
LANGUAGE plpgsql;
