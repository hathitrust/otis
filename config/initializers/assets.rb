# Be sure to restart your server when you modify this file.

if Rails.env.test?
  Rails.application.config.assets.prefix = "/useradmin"
end

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.precompile += %w[ckeditor/config.js]
