# pg-evolve #

Un outil simple pour la mise en oeuvre de bases de données PostgresSQL utilisant la méhode Evolutionary Database Design et Kubernetes.

## Comment utiliser ##

Créer votre propre image en utilisant cette image de base et chargant vos scripts d'évolution PostgresSQL dans le répertoire `/opt/pg-evolve/evolutions`.

Exemple:

```Dockerfile
FROM pg-evolve

COPY *.sql /opt/pg-evolve/evolutions/
```

Cette image peut etre utilisée comme `initContainer `Kubernetes pour effectuer les évolutions sur la base de données.

## Variables d'environnement ##

### `PGHOST` ###

Le nom d'hôte du serveur.

### `PGDATABASE` ###

Le nom de la base de données a utiliser.

### `PGUSER` ###

Le nom d'utilisateur pour se connecter au serveur PostgresSQL.

### `PGPASSWORD` ###

Le mot de passe pour se connecter au serveur PostgresSQL.

### `PGEVOLVE_SKIPCHECKSUMCHECK` (facultatif) ###

Si la valeur est `false`, désactive la vérification d'intégrité des évolutions.

### `PGEVOLVE_INSTALL_PATH` (facultatif) ###

Repertoire alternatif des scripts d'installation de pg-evolve.

### `PGEVOLVE_EVOLUTIONS_PATH` (facultatif) ###

Repertoire alternatif des scripts d'évolutions.
