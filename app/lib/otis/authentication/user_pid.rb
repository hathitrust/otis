# frozen_string_literal: true

module Otis
  module Authentication
    class UserPid < Keycard::Authentication::Method
      def apply
        if user_pid.nil?
          skipped('No user_pid found in request attributes')
        elsif (account = finder.call(user_pid))
          succeeded(account, "Account found for user_pid '#{user_pid}'")
        else
          failed("Account not found for user_pid '#{user_pid}'")
        end
      end

      private

      def user_pid
        attributes.user_pid
      end
    end
  end
end
