require "rails_helper"

RSpec.describe FailedChildrensBarredListEntries do
  let(:upload_file_hash) { Digest::SHA256.hexdigest("foo") }
  let(:key) { subject.entries_key(upload_file_hash) }
  let(:entry) { create(:childrens_barred_list_entry) }
  let(:form) { SupportInterface::UploadForm.new(upload_file_hash:) }

  subject(:service) { described_class.new }

  before do
    subject.clear(upload_file_hash)
  end

  describe "#get" do
    it "returns nil if there are no failed entries" do
      expect(subject.get(upload_file_hash)).to be_nil
    end

    it "returns the failed entries as FailedChildrensBarredListEntry instances" do
      subject.redis.set(key, [entry].to_json)

      expect(subject.get(upload_file_hash)).to eq(
        [FailedChildrensBarredListEntry.new(entry.attributes)]
      )
    end
  end

  describe "#set" do
    it "sets the failed entries" do
      form.failed_entries = [entry]
      subject.set(form)

      expect(subject.redis.get(key)).to eq([entry].to_json)
    end
  end

  describe "#clear" do
    it "clears the failed entries" do
      subject.redis.set(key, [entry].to_json)
      subject.clear(upload_file_hash)

      expect(subject.redis.get(key)).to be_nil
    end
  end

  describe "#entries_key" do
    it "returns the key for the failed entries" do
      expect(subject.entries_key(upload_file_hash)).to eq("cbl-failed-entries-#{upload_file_hash}")
    end
  end
end
