# OMGDOTS

The childhood paper classic, now online and multiplayer.

You can run this wherever you like, or [go here](https://omgdots.mrks.io) to play now.

## Run Locally via Nix

This project uses [Nix](https://nixos.org/nix/) for reproducible development environments. If you have Nix installed (version 2.4+), getting started is easy:

### Using `nix develop` (recommended)

```bash
# Enter the development shell
nix develop

# Start Redis in the background (if not already running)
redis-server --daemonize yes

# Install gems (first time only, or after Gemfile changes)
bundle install

# Run the Rails server
rails server -b 0.0.0.0

# Or run tests
rspec
```

### Using `nix-shell` (alternative)

```bash
nix-shell --run "redis-server --daemonize yes"
nix-shell --run "bundle install"
nix-shell --run "rails server -b 0.0.0.0"
nix-shell --run "rspec"
```

### Using the flake directly

```bash
# Enter development shell
nix develop

# Or run commands directly
nix run .#devShells.$(system).default
```

## Run Locally (Distrobox/Ruby)

If you prefer to use distrobox or your system Ruby:

```
distrobox create --image docker.io/library/ruby:3.4.1 --name omgdots --pull
distrobox enter omgdots
# Install dependencies via your system package manager
# For Debian/Ubuntu: sudo apt-get update && sudo apt-get install -y redis-server nodejs libsqlite3-dev yarn
bundle install
```

Then start the services:

* `redis-server` (or use an existing Redis instance)
* `rails server -b 0.0.0.0`

Navigate to `http://localhost:3000` in your browser.

## Deployment

This is currently deployed as a docker container via dokku on a personal server.

As docker containers go, this one is very simple It defaults to listening on port 3000, but this can be changed via the `PORT` environment variable.

A redis instance is required for the application to function, and can be provided via the `REDIS_URL` environment variable.

For dokku, this involved creating a redis service and linking it to the app

```
dokku redis:create omgdots-redis
dokku redis:link omgdots-redis omgdots
```
