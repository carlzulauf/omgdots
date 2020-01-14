source 'https://rubygems.org'

gem "rails"
gem "puma"
gem "sass-rails"
gem "haml"
gem "uglifier"
gem "coffee-rails"
gem "redis"
gem "redis-namespace"

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
  gem 'listen', '~> 3.0.5'
  gem "capistrano", "3.6.1"
  gem "capistrano-rails"
  gem "capistrano-chruby"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
