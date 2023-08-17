require "rails_helper"

RSpec.describe ConfirmChildrensBarredListEntries do
  let(:unconfirmed_entry) { create(:childrens_barred_list_entry, :unconfirmed) }

  subject(:service) { described_class.new }

  describe "#call" do
    it "confirms all unconfirmed entries matching the upload hash" do
      another_unconfirmed_entry = create(
        :childrens_barred_list_entry,
        :unconfirmed,
        last_name: "Brown",
        upload_file_hash: "123",
      )

      service.call(unconfirmed_entry.upload_file_hash)

      expect(unconfirmed_entry.reload).to be_confirmed
      expect(unconfirmed_entry.confirmed_at).to be_present
      expect(another_unconfirmed_entry.reload).not_to be_confirmed
    end
  end
end
