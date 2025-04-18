[![Tests](https://github.com/hathitrust/otis/actions/workflows/tests.yaml/badge.svg)](https://github.com/hathitrust/otis/actions/workflows/tests.yaml)
[![Coverage Status](https://coveralls.io/repos/github/hathitrust/otis/badge.svg?branch=main)](https://coveralls.io/github/hathitrust/otis?branch=main)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

## Table Of Contents

* [About the Project](#about-the-project)
* [Built With](#built-with)
* [Phases](#phases)
* [Project Set Up](#project-set-up)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
  * [Creating A Pull Request](#creating-a-pull-request)
* [Content Structure](#content-structure)
  * [Project Structure](#project-structure)
  * [Site Maps](#site-maps)
* [Design](#design)
* [Functionality](#functionality)
  * [Jira](#jira)
  * [Email](#email)
  * [GeoIP](#geoip)
* [Usage](#usage)
* [Tests](#tests)
* [Hosting](#hosting)
* [Resources](#resources)

## About The Project

Otis is named after the elevator company (because it's an elevated access tool). 
It manages users with elevated access, and institutions.

Users with elevated access are granted the ability to view and/or download page images that are not public domain, such as:
* patrons with disabilities
* partners doing copyright/quality review
* staff developers

## Built With

* Otis is a dockerized (Ruby on) Rails 8 application.
* It uses Bootstrap 5 for UI.
* Mariadb database.
* `keycard` and `checkpoint` gems for authentication & authorization.

## Phases

### Phase 1 - Currently doing

No current large initiative development.

### Phase 2 - Next Steps

No known near term tangible steps other than the normal basic maintenance.

### Phase 3 - Future Additions

User identity management.

## Project Set Up
### Prerequisites

Nothing beyond the ordinary (git, repo access, Docker).

### Installation

```
$ git clone https://github.com/hathitrust/otis.git
$ cd otis
$ docker compose build
$ ./bin/setup-dev.sh
```

Start web service:

```
docker compose up -d web
```

Development mode uses mysql via Docker with generated data from the `db:seed`
task and three dummy users with different levels of access via the
`otis:migrate_users` task. Starting the web container automatically runs these
tasks via `bin/init_dev_db.sh`.

To try the application, go to http://localhost:3000/useradmin and log in as one
of `{admin,staff,institution}@default.invalid`, in decreasing order of
administrative power.

### Creating A Pull Request

Nothing beyond the ordinary.

## Content Structure

It's a fairly standard Rails layout:

```
app/      # contains the Ruby, template and .erb files for the Rails app
bin/      # bin-stubs, setup and test utilities
config/   # some Rails boilerplate stuff, settings for Rails runtime & 3rd party utilities, localization
db/       # database schema and seeding files
.github/  # Github workflows
lib/      # Some custom rake tasks:
lib/tasks/clear_database.rake       # test/setup
lib/tasks/daily_digest.rake         # production cron-job
lib/tasks/institutions_export.rake  # production cron-job
lib/tasks/migrate_users.rake        # test/setup
log/      # Rails logs, pretty verbose but not always useful
public/   # Static assests, favicons and http status pages
test/     # Ruby tests (minitest style)
vendor/   # vendor/geoip, minimal test db
```

### Site Maps

There are only a few pages to go between:

```
(Fake login page for testing)
Users (landing page)
Approval Requests             # for renewal of users with elevated access 
Institutions
Contacts
Contact Types
Logs
Registrations                 # for new users
SSD Proxy Reports
```

Most pages have the standard CRU(D) operations (not a lot of Deletes), Rails style.

## Design

There is very little branding, since it is not at all facing the public.
There have been some adjustments to improve color contrast.
Otis uses `select2.org` JavaScript library to make searchable lists of items (users, institutions).
Also uses `Ckeditor` for rich text editing used in composing emails.

All index pages use Bootstrap Table (https://bootstrap-table.com) for data display. SSD Proxy Reports
has advanced search features server-side using Ransack (https://github.com/activerecord-hackery/ransack).
This approach is expected to be a model for updating the other index pages.

## Functionality

### Provisioning Users

Use the `bin/grants` utility to manage access. When called without parameters it emits a minimalist usage summary.
The usage screen summarizes the available actions (e.g., "view", "admin") and resource types (e.g., "ht_institution", "all")
for grant/revoke commands.

Examples:
```
bin/grants list
bin/grants grant user@example.com view all
bin/grants revoke user@example.com view all
```

### Jira

Uses the `jira-ruby` gem to add comments to tickets linked to new user registration.
The purpose of this is to show up-to-date status information of the new user registration.
One-way communication, only from Otis to Jira.

### Email

Uses Rails to send emails.

Registration sends an email to the new user, but not the supervisor.
New users are provided a link back to Otis to complete the registration.

Renewal sends an email to the new user and their supervisor inform them of the renewal process.
Supervisors are provided a link back to Otis to complete the renewal.

One of the Rake tasks (`lib/tasks/daily_digest.rake`) also sends emails to HT staff.

### GeoIP

Used for displaying information about proposed new user registrations.
Used for checking that new users are in the country they say they're in.

## Usage

Otis is an administrative tool in which HathiTrust staff can:

* register new elevated access users
* renew existing elevated access users
* view and add/edit HT member institutions, including billing information (for holdings) and authentication.
* manage institutional contacts (e.g. ETAS contact information).
* maintain logs with regards to granting/renewing elevated access

It was created as a replacement for a handful of perl applications that had to be run from the commandline.

Otis is of few HT projects currently attempting to do localization/i18n. The Japanese
localization has, however, not been vetted by a native speaker.

## Tests

To run all tests locally:

```
docker compose run --rm test bundle install
docker compose run --rm test
```

To run a single test class use an invocation along these lines:

```
docker compose run --rm test bundle exec ruby -I test test/controllers/ht_users_controller_test.rb
```

System tests, as usual, are not run by default. But if you do, it'd go a little something like:

```
docker compose run --rm system-test
```

A list of the mailer templates that can be previewed is at localhost:3000/useradmin/rails/mailers

## Hosting

Kubernetes.

Runs on port 3000 locally.

## Resources

Schema for the database that Otis interfaces with: https://github.com/hathitrust/db-image
