SET pg_evolve.major TO 0;
SET pg_evolve.minor TO 1;

CREATE TABLE IF NOT EXISTS pg_evolve_version (
  major int NOT NULL,
  minor int NOT NULL
);

CREATE OR REPLACE FUNCTION pg_evolve_needs_upgrade (
  major int,
  minor int
)
RETURNS boolean
AS $need_upgrade$
DECLARE
  current_major int;
  current_minor int;
BEGIN
  SELECT p.major INTO current_major FROM pg_evolve_version p;
  SELECT p.minor INTO current_minor FROM pg_evolve_version p;

  RETURN major > current_major OR (major = current_major AND minor > current_minor);
END
$need_upgrade$ LANGUAGE plpgsql;


DO $$
BEGIN
  IF (SELECT COUNT(*) FROM pg_evolve_version) = 0
  THEN
    INSERT INTO pg_evolve_version
    VALUES (
      (SELECT current_setting('pg_evolve.major')::int),
      (SELECT current_setting('pg_evolve.minor')::int)
    );
  END IF;
END;
$$
LANGUAGE plpgsql;
