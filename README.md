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

To enable W3C HTML validation of OTIS pages, use the following.
These tests are not run by default since they rely on an external service.

```
docker-compose run -e W3C_VALIDATION=1 test
```

To run a single test class use an invocation along these lines:

```
docker-compose run test bundle exec ruby -I test test/controllers/ht_users_controller_test.rb
```

System tests, as usual, are not run by default.

```
docker-compose run system-test
```
