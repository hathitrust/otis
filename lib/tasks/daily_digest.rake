# frozen_string_literal: true

namespace :otis do
  desc "Sends daily to-do list of action items to configured recipients"
  task send_daily_digest: :environment do
    if ENV["RAKE_DEFAULT_URL_HOST"]
      ActionMailer::Base.default_url_options[:host] = ENV["RAKE_DEFAULT_URL_HOST"]
    end
    Otis::DailyDigest.send
  end
end
