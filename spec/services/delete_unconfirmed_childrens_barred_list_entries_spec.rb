require "rails_helper"

RSpec.describe DeleteUnconfirmedChildrensBarredListEntries do
  let(:unconfirmed_entry) { create(:childrens_barred_list_entry, :unconfirmed) }

  subject(:service) { described_class.new }

  describe "#call" do
    it "deletes all unconfirmed entries matching the upload hash" do
      another_unconfirmed_entry = create(
        :childrens_barred_list_entry,
        :unconfirmed,
        last_name: "Brown",
        upload_file_hash: "123",
      )

      service.call(unconfirmed_entry.upload_file_hash)

      expect(ChildrensBarredListEntry.count).to eq(1)
      expect(ChildrensBarredListEntry.first).to eq(another_unconfirmed_entry)
    end
  end
end
