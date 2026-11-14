# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# The Sass sources are compiled into app/assets/builds by dartsass-rails, so
# only serve the built CSS, not the sources themselves.
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/stylesheets")
