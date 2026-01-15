# frozen_string_literal: true

RSpec.describe Otis::LogTransfer do
  let(:transfer) { described_class.new }

  around(:each) do |example|
    Dir.mktmpdir("otis-log-transfer") do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  describe "#query_time" do
    context "when a query has taken place" do
      it "returns a `Time` in the recent past" do
        transfer.imgsrv_logs
        expect(transfer.query_time).to be_a(Time)
        expect(Time.now - transfer.query_time).to be < 1.hour
      end
    end

    context "when no query has taken place" do
      it "returns a `Time` in the distant past" do
        expect(transfer.query_time).to be_a(Time)
        expect(Time.now - transfer.query_time).to be > 1.year
      end
    end
  end

  describe "#imgsrv_logs" do
    it "returns two log files" do
      expect(transfer.imgsrv_logs.count).to eq(2)
    end
  end

  describe "#transfer_log" do
    it "transfers the contents and returns the destination path" do
      source = transfer.imgsrv_logs[0]["Path"]
      destination = transfer.transfer_log(source_path: source, destination_directory: @tmpdir)
      expect(File.exist?(destination)).to eq(true)
      expect(File.size(destination)).to be > 0
    end

    it "transfers a gzipped version if we asked for the pre-gzipped version" do
      # Get the log that has a gzip suffix and strip it.
      source = transfer.imgsrv_logs.find do |log|
        log["Path"].end_with?(".gz")
      end["Path"].sub(/\.gz$/, "")
      # Ask for that nonexistent file
      destination = transfer.transfer_log(source_path: source, destination_directory: @tmpdir)
      expect(File.exist?(destination)).to eq(true)
      expect(destination.end_with?(".gz")).to eq(true)
      expect(File.size(destination)).to be > 0
    end
  end
end
