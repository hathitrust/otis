# frozen_string_literal: true

RSpec.describe Otis::LogImporter do
  let(:importer) { described_class.new }
  let(:fixtures_dir) {
    ["spec", "fixtures", "ulib-logs", "archive", "macc-ht-web-189.umdl.umich.edu", "var", "log", "babel"]
  }
  let(:text_log) { Rails.root.join(*fixtures_dir, "access-imgsrv_downloads.log-20250901") }
  let(:gzip_log) { Rails.root.join(*fixtures_dir, "access-imgsrv_downloads.log-20250902.gz") }

  around(:each) do |example|
    HTSSDProxyReport.delete_all
    # This is mainly to isolate journals from subsequent tests
    Dir.mktmpdir("otis-log-importer") do |tmpdir|
      @tmpdir = tmpdir
      ClimateControl.modify(OTIS_LOG_IMPORT_JOURNAL_DIRECTORY: tmpdir) do
        example.run
      end
    end
  end

  describe "#run" do
    it "populates the table with two entries" do
      expect do
        importer.run
      end.to change { HTSSDProxyReport.count }.by(2)
    end

    it "creates full-populated records" do
      importer.run
      # Spot-check one of the new records
      report = HTSSDProxyReport.first
      expect(report[:in_copyright]).not_to be_nil
      expect(report[:yyyy]).to be > 0
      expect(report[:yyyymm].length).to be > 0
      expect(report[:datetime]).to be_a(Time)
      expect(report[:htid].length).to be > 0
      expect(report[:is_partial]).not_to be_nil
      expect(report[:email].length).to be > 0
      expect(report[:inst_code].length).to be > 0
      expect(report[:sha].length).to be > 0
    end

    it "records useful stats" do
      importer.run
      expect(importer.stats[:files_scanned]).to eq(2)
      expect(importer.stats[:entries_found]).to eq(2)
      expect(importer.stats[:entries_added]).to eq(2)
    end

    it "ignores entries earlier than the last run file" do
      # Write a last run file with the current date
      File.open(importer.journal_path, "w") do |file|
        file.puts Time.now
      end
      # ... and travel into the future
      Timecop.travel(Time.now + 24.hours) do
        # There are no newer log files to scan
        expect(importer.run.stats[:files_scanned]).to eq(0)
      end
    end
  end

  describe "#last_import" do
    context "with a journal" do
      it "returns a Time based on the file content" do
        now = Time.now.to_s
        journal = File.join(@tmpdir, described_class::LOG_IMPORT_JOURNAL_NAME)
        File.open(journal, "w") { |file| file.puts now }
        expect(importer.last_import).to be_a(Time)
        expect(importer.last_import).to eq(now)
      end
    end

    context "with no journal" do
      it "returns a Time in the past" do
        expect(importer.last_import).to be_a(Time)
        expect(importer.last_import).to be < Time.now
      end
    end
  end

  describe "#journal_directory" do
    context "with path set in ENV" do
      it "returns the path set by environment" do
        expect(importer.journal_directory).to eq(@tmpdir)
      end
    end

    context "with no path set in ENV" do
      it "returns the default path" do
        ClimateControl.modify(OTIS_LOG_IMPORT_JOURNAL_DIRECTORY: nil) do
          expect(importer.journal_directory).to eq(described_class::DEFAULT_JOURNAL_DIRECTORY)
        end
      end
    end

    context "with a non-writable path" do
      it "raises" do
        ClimateControl.modify(OTIS_LOG_IMPORT_JOURNAL_DIRECTORY: "/sys") do
          expect do
            importer.journal_directory
          end.to raise_error(/writable/)
        end
      end
    end
  end

  describe "#process_file" do
    context "with a log file having one relevant entry" do
      it "adds one entry to the database" do
        expect do
          importer.process_file(source_file: text_log, log_file: text_log)
        end.to change { HTSSDProxyReport.count }.by(1)
      end
    end

    context "with a gzipped log file having one relevant entry and one malformed entry" do
      it "adds one entry to the database" do
        expect do
          importer.process_file(source_file: gzip_log, log_file: gzip_log)
        end.to change { HTSSDProxyReport.count }.by(1)
      end
    end

    context "loading the same log file twice" do
      it "adds nothing to the database from the second attempt" do
        importer.process_file(source_file: text_log, log_file: text_log)
        expect do
          importer.process_file(source_file: text_log, log_file: text_log)
        end.to change { HTSSDProxyReport.count }.by(0)
      end
    end
  end

  describe "#translate_remote_user" do
    context "with no corresponding HTUser" do
      it "returns the remote user" do
        expect(importer.translate_remote_user("no_such_user")).to eq "no_such_user"
      end
    end

    context "with corresponding HTUser" do
      it "returns the email value from the database" do
        user = create(:ht_user)
        expect(importer.translate_remote_user(user.userid)).to eq user.email
      end
    end
  end
end
