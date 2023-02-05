FROM docker.io/library/ruby:2.7.7

RUN apt-get update -qq \
  && apt-get install -y nodejs

WORKDIR /app

# install gems on their own, to speedup rebuilds
COPY Gemfile* /app/
RUN gem install bundler -v 2.1.4 \
  && bundle config set deployment 'true' \
  && bundle config set without 'development test' \
  && bundle install

# every file change triggers this step and below to repeat
#  so, try to do as much above here as possible
COPY . /app

RUN bin/build-assets.sh
CMD ["bin/run-server.sh"]
