#!/bin/sh

export RAILS_ENV=production
export SECRET_KEY_BASE=fake # just to allow rails env to boot

bundle exec rails assets:precompile
