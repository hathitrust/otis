# Otis Elevated Access Tool

## Initial setup
### 1. Getting a local copy, bundle install gems, and execute setup script

```
$ git clone https://github.com/hathitrust/otis.git
$ cd otis
$ bundle install
```

### 2. Database

Development mode uses sqlite3 with generated data. The keycard and
checkpoint databases also need to be set up. The `otis:migrate_users` task
sets up three dummy users with different levels of access (this is done
automatically for the `test` environment by the test script).

```
bundle exec rake keycard:migrate RAILS_ENV=development
bundle exec rake keycard:migrate RAILS_ENV=test
bundle exec rake checkpoint:migrate RAILS_ENV=development
bundle exec rake checkpoint:migrate RAILS_ENV=test
bundle exec rake db:setup
bundle exec rake otis:migrate_users RAILS_ENV=development
```

### 3. Testing

```
bundle exec rake test
```

### 4. Trying it out

```
bundle exec rails s
```

Go to http://localhost:3000/useradmin and log in as `somebody@default.invalid`

### 5. Staged version

* Living at https://moseshll.babel.hathitrust.org/useradmin-staging
* Deploy via moku with ssh deployhost-001 deploy useradmin-staging the-name-of-your-branch

