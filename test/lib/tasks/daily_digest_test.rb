# frozen_string_literal: true

require "test_helper"

module Otis
  class DailyDigestTaskTest < ActiveSupport::TestCase
    # Work around ActionMailer::Base habit of clearing deliveries array
    # after Rake task invocation.
    class MailSnoop
      SNOOPED_MAIL = []
      def self.delivering_email(mail)
        SNOOPED_MAIL << mail
      end
    end

    def setup
      Application.load_tasks
    end

    test "task runs without errors" do
      Rake::Task["otis:send_daily_digest"].invoke
    end

    test "link uses default URL host from environment" do
      ENV["RAKE_DEFAULT_URL_HOST"] = "example.com/otis"
      create(:ht_user, expires: Date.today + 5)
      ActionMailer::Base.register_interceptor(MailSnoop)
      Rake::Task["otis:send_daily_digest"].execute
      MailSnoop::SNOOPED_MAIL.last.tap do |mail|
        assert_match "example.com/otis/ht_user", mail.html_part.body.decoded
      end
      ActionMailer::Base.unregister_interceptor(MailSnoop)
    end
  end
end
