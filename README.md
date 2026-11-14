# OMGDOTS

The childhood paper classic, now online and multiplayer.

You can run this wherever you like, or [go here](https://omgdots.mrks.io) to play now.

## Run Locally

The dev environment comes from `flake.nix` (Ruby, Bundler, Redis and the
libraries native gems build against). Gems install into
`~/.local/share/gems/omgdots/`, not the system Ruby. There is no Node.js:
JavaScript is served as ES modules through importmap-rails, and Sass is
compiled by dartsass-rails.

```bash
direnv allow      # or: nix develop
bundle install
bin/dev           # runs Procfile.dev (rails, sass watcher, redis) with foreman
```

Then open http://localhost:3017.

`bin/dev` installs foreman the first time it runs. Use `PORT=...` to pick another
port, or `bin/dev -b 0.0.0.0` to listen on all interfaces. To run the processes
yourself instead, start each in its own terminal:

```bash
cd db && redis-server --bind 127.0.0.1 ::1   # saves to db/dump.rdb
bin/rails dartsass:watch                     # rebuilds app/assets/builds/application.css
bin/rails server -p 3017
```

Redis defaults to `localhost:6379`. Set `REDIS_URL` to use a different one.

`bundle exec rspec` runs the tests.

## Deployment

This is currently deployed as a docker container via dokku on a personal server,
built from the repo's `Dockerfile`. There is no other deploy tooling.

As docker containers go, this one is very simple. The image installs gems and
precompiles assets at build time, then runs `rails server`. Set
`RAILS_ENV=production` and `SECRET_KEY_BASE` in the container's environment. It
listens on port 3000 unless `PORT` says otherwise.

A redis instance is required for the application to function, and can be provided via the `REDIS_URL` environment variable.

For dokku, this involved creating a redis service and linking it to the app

```
dokku redis:create omgdots-redis
dokku redis:link omgdots-redis omgdots
```
