require "rails_helper"

# Key derivation moved from SHA-1 to SHA-256, which no ciphertext records, so a
# silent revert of the configuration would not surface until rows stopped
# decrypting in production. These assert the intended end state directly.
RSpec.describe "Active Record encryption configuration" do
  let(:config) { ActiveRecord::Encryption.config }

  it "derives keys with SHA-256" do
    expect(config.hash_digest_class).to eq OpenSSL::Digest::SHA256
  end

  it "keeps no previous schemes, so SHA-256 is the only digest that can read" do
    expect(config.previous_schemes).to be_empty
  end

  it "gives no encrypted attribute a fallback to an older digest" do
    types = [
      DsiUser.type_for_attribute(:email),
      DsiUser.type_for_attribute(:first_name),
      ChildrensBarredListEntry.type_for_attribute(:last_name),
      ChildrensBarredListEntry.type_for_attribute(:trn)
    ]

    expect(types.map(&:previous_types)).to all(be_empty)
  end

  # The counterpart of this ran green before support_sha1_for_non_deterministic_encryption
  # was removed. Anything still holding SHA-1 ciphertext is now unreadable for good,
  # which is why pii:verify had to report nothing before this change shipped.
  context "with a row still written under SHA-1" do
    it "cannot read a non-deterministic column" do
      entry = create(:childrens_barred_list_entry, trn: "1234567")
      write_under_sha1(entry, :trn, "1234567")

      expect { entry.reload.trn }.to raise_error(ActiveRecord::Encryption::Errors::Decryption)
    end

    # This is the failure that mattered: a search reporting no record for a
    # barred person, with no error anywhere.
    it "cannot find a barred list entry by search" do
      entry = create(:childrens_barred_list_entry, last_name: "Doe", date_of_birth: "1980-01-01")
      write_under_sha1(entry, :searchable_last_name, "doe")
      write_under_sha1(entry, :date_of_birth, "1980-01-01")

      expect(ChildrensBarredListEntry.search(last_name: "Doe", date_of_birth: "1980-01-01")).to be_nil
    end
  end
end
