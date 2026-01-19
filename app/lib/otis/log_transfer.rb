# frozen_string_literal: true

require "date"
require "json"
require "zinzout"

module Otis
  class LogTransfer
    attr_reader :query_time

    def initialize
      @query_time = Time.at 0
    end

    def rclone_config_path
      ENV.fetch("OTIS_RCLONE_CONFIG", Rails.root.join("config", "rclone.conf").to_s)
    end

    # Call rclone to list the relevant log files from ictc and macc
    # @return Hash from JSON returned by `rclone` sorted chronologically from earliest
    def imgsrv_logs
      @imgsrv_logs ||= begin
        cmd = <<~RCLONE.gsub(/\s+/, " ").strip
          rclone
          --config #{rclone_config_path}
          lsjson
          -R
          --files-only
          --no-mimetype
          --include '/{macc,ictc}-ht-web-*.umdl.umich.edu/var/log/babel/access-imgsrv_downloads.log*'
          ulib-logs:/ulib-logs/archive
        RCLONE
        @query_time = Time.now
        JSON.parse(`#{cmd}`)
      end.sort! do |a, b|
        Time.parse(a["ModTime"]) <=> Time.parse(b["ModTime"])
      end
    end

    # @return String the destination path to log file that was transferred
    def transfer_log(source_path:, destination_directory:)
      # Try the path that lsjson returned to us
      destination = File.join(destination_directory, File.basename(source_path))
      success = system(rclone_copyto_command(source_path: source_path, destination: destination))
      if !success && !source_path.end_with?(".gz")
        # Didn't get it? If we asked for plain text and the file got gzipped while we were
        # not looking, ask for it again but gzipped this time.
        destination += ".gz"
        # Ignore the return since the absence of the requested file will indicate that
        # an error has occurred.
        system(rclone_copyto_command(source_path: source_path + ".gz", destination: destination))
      end
      destination
    end

    private

    def rclone_copyto_command(source_path:, destination:)
      <<~RCLONE.gsub(/\s+/, " ").strip
        rclone
        --config #{rclone_config_path}
        --error-on-no-transfer
        copyto
        #{File.join("ulib-logs:/ulib-logs/archive", source_path)}
        #{destination}
      RCLONE
    end
  end
end
