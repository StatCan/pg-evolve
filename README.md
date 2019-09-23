# pg-evolve #

A simple Evolutionary Database (EDD) Design tool for PostgresSQL for running database evolutions in Kubernetes.

## How to Use ##

Create you own image using this image as a base and load your PostgresSQL evolution scripts to `/opt/pg-evolve/evolutions`.

Example:

```Dockerfile
FROM pg-evolve

COPY *.sql /opt/pg-evolve/evolutions/
```

This image can then be used as a Kubernetes `initContainer` to peform database evolutions on every build.

## Environment Variables ##

### `PGHOST` ###

The host name of the machine on which the server is running.

### `PGDATABASE` ###

The name of the database to use.

### `PGUSER` ###

The user name to connect to the PostgresSQL server.

### `PGPASSWORD` ###

The password to connect to the PostgresSQL server.

### `PGEVOLVE_SKIPCHECKSUMCHECK` (optional) ###

If set to `false`, disable the integrity check for evolutions.

### `PGEVOLVE_INSTALL_PATH` (optional) ###

Overrides the path to the install scripts for pg-evolve.

### `PGEVOLVE_EVOLUTIONS_PATH` (optional) ###

Overrides the path to look for evolutions.
