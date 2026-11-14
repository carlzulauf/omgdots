FROM ruby:4.0

# No extra system packages: there is no Node.js (importmap serves JS, and the
# sass-embedded gem bundles its own compiler) and no database. The full
# ruby image already has the compiler and headers native gems build against.

WORKDIR /app

# Without this the image boots in development, bound to localhost only.
ENV RAILS_ENV=production

# install gems on their own, to speedup rebuilds
COPY Gemfile* /app/
RUN gem install bundler:4.0.24 \
 && bundle config set deployment 'true' \
 && bundle config set without 'development test' \
 && bundle install

# every file change triggers this step and below to repeat
#  so, try to do as much above here as possible
COPY . /app

RUN bin/build-assets.sh
CMD ["bin/run-server.sh"]
