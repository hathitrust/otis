# Otis Elevated Access Tool

## Initial setup
### 1. Getting a local copy, bundle install gems, and execute setup script

```
$ git clone https://github.com/hathitrust/otis.git
$ cd otis
$ bundle install
```

### 2. Database

Use a local copy of the `ht_repository` database. Only the `ht_users` table
is needed at the moment.

```
$ ssh <some HathiTrust server>
$ mysqldump -u <MySQL user> -p -h <MySQL host> ht_repository ht_users
```

### 3. Testing

We still need a CI setup, but for now we have Rails tests and RuboCop:

```
bin/rails test test/
bundle exec rubocop
```
