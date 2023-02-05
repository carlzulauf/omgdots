#!/bin/sh

export RAILS_ENV=production
export SECRET_KEY_BASE=fake # just to allow rails env to boot
export NODE_ENV=production

bundle exec rails assets:precompile
