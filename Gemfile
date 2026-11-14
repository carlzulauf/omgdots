source 'https://rubygems.org'

# Ruby 4.0 required - matches nixpkgs ruby_4_0
ruby "~> 4.0"

gem "rails", "~> 8.1.0"
gem "puma"
gem "propshaft"
gem "importmap-rails"
gem "dartsass-rails"
gem "haml"
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
end
