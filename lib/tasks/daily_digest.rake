# frozen_string_literal: true

namespace :otis do
  desc "Sends daily to-do list of action items to configured recipients"
  task send_daily_digest: :environment do
    Otis::DailyDigest.send
  end
end
