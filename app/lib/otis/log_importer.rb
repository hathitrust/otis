# frozen_string_literal: true

require "date"
require "json"
require "zinzout"

module Otis
  class LogImporter
    attr_reader :user_map, :stats, :transfer

    # Always use this filename, the location may vary
    LOG_IMPORT_JOURNAL_NAME = "otis_last_log_import.txt"
    # It is unlikely we will ever use this
    DEFAULT_JOURNAL_DIRECTORY = "/var"

    def initialize
      @user_map = {}
      @stats = {
        files_scanned: 0,
        entries_found: 0,
        entries_added: 0
      }
      @transfer = LogTransfer.new
      # Eager load so we raise if the directory is not writable
      @journal_path = journal_path
    end

    # TODO: milemarker/Prometheus

    # Iterate each record of the rclone output in order from earliest mod time
    def run
      # Write files into a temp directory and delete them as they are processed
      # so they don't pile up.
      Dir.mktmpdir("otis_log_import") do |tempdir|
        @transfer.imgsrv_logs.each do |log_struct|
          mod_time = Time.parse log_struct["ModTime"]
          # Bail out if mod time is less than (earlier than) last import
          if mod_time < last_import
            next
          end

          temp_file = transfer.transfer_log(
            source_path: log_struct["Path"],
            destination_directory: tempdir
          )
          Rails.logger.info "processing log #{temp_file} from #{log_struct["Path"]}"
          process_file(source_file: log_struct["Path"], log_file: temp_file)
          File.unlink temp_file
          @stats[:files_scanned] += 1
        end
      end
      write_journal
      self
    end

    # Returns Time object, either the last time the process was run,
    # or the Epoch to represent "distant past"
    def last_import
      @last_import ||= if File.exist?(journal_path)
        File.open(journal_path) do |file|
          Time.parse file.gets.chomp
        end
      else
        Time.at 0
      end
    end

    def write_journal
      File.open(journal_path, "w") do |file|
        file.puts transfer.query_time
      end
    end

    # For now this file will be the same `babel/logs` location as its predecessor
    def journal_path
      @journal_path ||= File.join(journal_directory, LOG_IMPORT_JOURNAL_NAME)
    end

    def journal_directory
      @journal_directory ||= begin
        dir = ENV.fetch("OTIS_LOG_IMPORT_JOURNAL_DIRECTORY", DEFAULT_JOURNAL_DIRECTORY)
        if !File.writable?(dir)
          raise "journal directory #{dir} is not writable"
        end
        dir
      end
    end

    # `source_file` is the remote path to the original, for reporting JSON parser errors.
    # `log_file` is transferred local copy we want to process.
    def process_file(source_file:, log_file:)
      Zinzout.zin(log_file, encoding: "utf-8") do |infile|
        infile.each_with_index do |line, line_number|
          begin
            entry = JSON.parse(line)
          rescue JSON::ParserError
            Rails.logger.error "unparseable JSON in #{log_file} line #{line_number + 1} (#{source_file})"
            next
          end
          if relevant_log_entry?(entry)
            @stats[:entries_found] += 1
            create_report(entry)
          end
        end
      end
    end

    # Translate remote_user_processed string into ht_users.email
    # Keeps a local cache to keep database activity within reason
    def translate_remote_user(remote_user)
      user_map[remote_user] ||= begin
        ht_user = HTUser.where(userid: remote_user).first
        if ht_user.nil?
          Rails.logger.warn "REMOTE_USER #{remote_user} not in ht_users"
          remote_user
        else
          ht_user.email
        end
      end
    end

    private

    # Returns true iff all of these are true:
    # role is "ssdproxy"
    # access is "success"
    # mode is "download"
    # datetime is on or after last import
    def relevant_log_entry?(entry)
      entry["role"] == "ssdproxy" &&
        entry["access"] == "success" &&
        entry["mode"] == "download" &&
        Time.parse(entry["datetime"]) >= last_import
    end

    def create_report(entry)
      datetime = Time.parse entry["datetime"]
      report = HTDownload.new(
        in_copyright: entry["ic"],
        yyyy: datetime.year,
        yyyymm: datetime.strftime("%Y%m"),
        datetime: datetime,
        htid: entry["id"],
        is_partial: entry["is_partial"],
        email: translate_remote_user(entry["remote_user_processed"]),
        inst_code: entry["inst_code"],
        role: entry["role"],
        pages: entry["seq"].split(",").count
      )
      # Call `.save` and not `.save!` on this object because its SHA may
      # violate uniqueness, which is perfectly okay.
      if report.save
        @stats[:entries_added] += 1
      else
        # No need to log if there's only one error and it's a uniqueness violation.
        # The actual error is "Validation failed: Sha has already been taken"
        if report.errors.messages.keys == [:sha] &&
            report.errors.messages[:sha].count == 1 &&
            report.errors.messages[:sha][0].match(/already/)
          return
        end
        Rails.logger.error "could not save: #{report.errors.messages} from #{report.inspect} (#{entry})"
      end
    end
  end
end
