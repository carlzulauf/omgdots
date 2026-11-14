# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
end

def load_saved_game(name)
  path = Rails.root.join("spec", "support", "games", "#{name}.json")
  json = File.read(path)
  DotsGame.new JSON.parse(json)
end

# A separate connection to the models' Redis, under the same namespace (see
# config/initializers/redis.rb): stands in for another app server.
def new_model_redis_connection
  client = Redis.new(url: ENV["REDIS_URL"])
  ns = Rails.application.config.x.redis_namespace
  ns ? Redis::Namespace.new(ns, redis: client) : client
end
