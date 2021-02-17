# Otis Administrative Tools

## Initial setup
### 1. Set up development

```
$ git clone https://github.com/hathitrust/otis.git
$ cd otis
$ docker-compose build
$ docker-compose run web bundle install
```

### 2. Trying it out

```
docker-compose up -d web
```

Development mode uses mysql via Docker with generated data from the `db:seed`
task and three dummy users with different levels of access via the
`otis:migrate_users` task. Starting the web container automatically runs these
tasks via `bin/init_dev_db.sh`.

To try the application, go to http://localhost:3000/useradmin and log in as one
of `{admin,staff,institution}@default.invalid`, in decreasing order of
administrative power.

### 3. Running tests

```
docker-compose run test
```
