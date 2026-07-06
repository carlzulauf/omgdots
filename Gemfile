source 'https://rubygems.org'

# Ruby 3.4 required - matches nixpkgs ruby_3_4
ruby "~> 3.4"

gem "rails", "7.2.0"
gem "puma"
gem "sass-rails", "~> 5.0.7"
gem "haml"
gem "uglifier"
gem "coffee-rails", "~> 4.2.2"
gem "redis"
gem "redis-namespace"
gem "benchmark"

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem "pry-rails"
gem "dotenv-rails"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem "rspec-rails"
end

group :development do
  gem 'web-console'
  gem 'listen', '~> 3.5'
end
