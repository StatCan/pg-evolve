SET pg_evolve.major TO 0;
SET pg_evolve.minor TO 3;

DO $$
BEGIN
  IF (SELECT pg_evolve_needs_upgrade (
    (SELECT current_setting('pg_evolve.major')::int),
    (SELECT current_setting('pg_evolve.minor')::int)
  ))
  THEN
    ALTER TABLE pg_evolve_evolutions
    ADD COLUMN sha256 char(64);

    DROP FUNCTION pg_evolve_get_evolutions();
    CREATE FUNCTION pg_evolve_get_evolutions ()
    RETURNS TABLE(
      filename varchar(255),
      sha256 char(64)
    )
    AS $get$
    SELECT filename, sha256 FROM pg_evolve_evolutions;
    $get$ LANGUAGE SQL;

    CREATE OR REPLACE FUNCTION pg_evolve_applied (
      filename varchar(255),
      releaseNumber varchar(255),
      sha256 char(64)
    )
    RETURNS void
    AS $apply$
    BEGIN
      INSERT INTO pg_evolve_evolutions (filename, releaseNumber, applied, sha256)
      VALUES (filename, releaseNumber, NOW(), sha256);
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
