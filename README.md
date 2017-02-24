# pg-patch

## Installation
To setup database for the first time use:

1. Create database with `psql -h 127.0.0.1 -p 5432 -U postgres -f init/db_setup.sql -v new_database=demodb`
2. Install demodb into created database `./run.sh -h 127.0.0.1 -p 5432 -U demodb_owner -d demodb`

## Patch
```sh
./run.sh -h 127.0.0.1 -p 5432 -U demodb_owner -d demodb
```
