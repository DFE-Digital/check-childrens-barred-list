require "rails_helper"

RSpec.describe DeleteUnconfirmedEntriesWorker do
  describe "#perform" do
    before do
      create(:childrens_barred_list_entry, last_name: "Smith")
      create(:childrens_barred_list_entry, :unconfirmed, last_name: "Wilson")
    end

    it "deletes the unconfirmed entry" do
      expect { DeleteUnconfirmedEntriesWorker.new.perform }
        .to change { ChildrensBarredListEntry.count }.by(-1)
    end
  end
end
