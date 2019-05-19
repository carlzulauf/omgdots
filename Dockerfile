FROM ruby:2.6
RUN apt-get update -qq \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV APP_HOME=/www

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 4 --retry 2

COPY . ./

CMD ["rails", "server", "-b", "0.0.0.0"]
