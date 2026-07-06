FROM ruby:3.4

RUN apt-get update -qq && apt-get install -y nodejs libsqlite3-dev rsync

WORKDIR /app

# install gems on their own, to speedup rebuilds
COPY Gemfile* /app/
RUN gem install bundler:4.0.15 \
 && bundle config set deployment 'true' \
 && bundle config set without 'development test' \
 && bundle install

# every file change triggers this step and below to repeat
#  so, try to do as much above here as possible
COPY . /app

RUN bin/build-assets.sh
CMD ["bin/run-server.sh"]
