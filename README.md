# OMGDOTS

The childhood paper classic, now online and multiplayer.

## Run Locally

Getting this running via distrobox is fairly easy.

```
distrobox create --image docker.io/library/ruby:2.7.8 --name omgdots --pull
distrobox enter omgdots
sudo apt-get update -qq && sudo apt-get install -y nodejs libsqlite3-dev yarn rsync tmux redis
bundle install
```

Once the above steps are completed, a known working approach is starting a tmux session from the project directory, and creating two tabs running the following commands:

* `rails server`
* `redis-server`

Then, in a browser, navigate to `localhost:3000`

## Deployment

This is currently deployed as a docker container via dokku on a personal server.

As docker containers go, this one is very simple It defaults to listening on port 3000, but this can be changed via the `PORT` environment variable.

A redis instance is required for the application to function, and can be provided via the `REDIS_URL` environment variable.

For dokku, this involved creating a redis service and linking it to the app

```
dokku redis:create omgdots-redis --image-version 6.0.16
dokku redis:link omgdots-redis omgdots
```
