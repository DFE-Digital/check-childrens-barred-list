require "rails_helper"

RSpec.describe Pii::Verifier do
  subject(:verifier) { described_class.new(logger: Logger.new(log)) }

  let(:log) { StringIO.new }

  describe "#call" do
    context "when every row was written under the current digest" do
      it "counts nothing" do
        create(:dsi_user)
        create(:childrens_barred_list_entry)

        expect(verifier.call).to be_zero
      end
    end

    context "when a deterministic column still holds SHA-1 ciphertext" do
      it "counts it and names it in the log" do
        entry = create(:childrens_barred_list_entry)
        write_under_sha1(entry, :searchable_last_name, entry.searchable_last_name)

        aggregate_failures do
          expect(verifier.call).to eq 1
          expect(log.string).to include "ChildrensBarredListEntry##{entry.id}.searchable_last_name"
        end
      end
    end

    # The model's own type has a SHA-1 fallback while
    # support_sha1_for_non_deterministic_encryption is set, so it reads these rows
    # happily. Verification has to see them anyway, because they become unreadable
    # the moment that setting is removed.
    context "when a non-deterministic column still holds SHA-1 ciphertext" do
      it "counts it even though the application can still read it" do
        entry = create(:childrens_barred_list_entry, trn: "1234567")
        write_under_sha1(entry, :trn, "1234567")

        aggregate_failures do
          expect(entry.reload.trn).to eq "1234567"
          expect(verifier.call).to eq 1
        end
      end
    end

    # It decrypts cleanly under SHA-256, so only checking the result catches it.
    context "when a value was encrypted twice" do
      it "counts it" do
        dsi_user = create(:dsi_user)
        dsi_user.update_column(:first_name, DsiUser.type_for_attribute(:first_name).serialize("Steven"))

        aggregate_failures do
          expect(verifier.call).to eq 1
          expect(log.string).to include "DsiUser##{dsi_user.id}.first_name"
        end
      end
    end

    context "after the re-encryptor has run" do
      it "counts nothing" do
        dsi_user = create(:dsi_user)
        entry = create(:childrens_barred_list_entry)
        write_under_sha1(dsi_user, :email, dsi_user.email)
        write_under_sha1(entry, :date_of_birth, entry.date_of_birth)

        Pii::ReEncryptor.new(logger: Logger.new(File::NULL)).call

        expect(verifier.call).to be_zero
      end
    end

    # SearchLog is last in the model order. A sample shared across models would
    # report its count and never any of its ids.
    context "when an earlier model has more failures than the sample holds" do
      it "still names the later models in the log" do
        stub_const("#{described_class}::SAMPLE_LIMIT", 2)
        3.times { write_under_sha1(create(:dsi_user), :email, "legacy@example.com") }
        search_log = create(:search_log, dsi_user: create(:dsi_user), last_name: "Doe")
        write_under_sha1(search_log, :last_name, "Doe")

        aggregate_failures do
          expect(verifier.call).to eq 4
          expect(log.string).to include "SearchLog##{search_log.id}.last_name"
        end
      end
    end

    context "with unreadable rows in more than one model" do
      it "sums the counts across all of them" do
        write_under_sha1(create(:dsi_user), :email, "legacy@example.com")
        write_under_sha1(create(:childrens_barred_list_entry), :first_names, "John")
        write_under_sha1(create(:search_log, dsi_user: create(:dsi_user), last_name: "Doe"), :last_name, "Doe")

        expect(verifier.call).to eq 3
      end
    end

    # handle_deserialize_error returns the raw ciphertext instead of raising when
    # support_unencrypted_data is true, and Scheme inherits that from the global
    # unless the scheme pins it. Inheriting a true would report every row readable
    # and take the gate in front of the irreversible cleanup silently green.
    context "when support_unencrypted_data is enabled globally" do
      it "still counts a SHA-1 row" do
        dsi_user = create(:dsi_user)
        write_under_sha1(dsi_user, :email, "legacy@example.com")
        allow(ActiveRecord::Encryption.config).to receive(:support_unencrypted_data).and_return(true)

        expect(verifier.call).to be_positive
      end
    end

    # A missing key is not a property of any row. Reported as unreadable rows it
    # would look like mass corruption and point at a restore.
    context "when the encryption configuration is broken" do
      it "raises rather than reporting every row unreadable" do
        create(:dsi_user)
        allow(ActiveRecord::Encryption.config).to receive(:deterministic_key).and_raise(
          ActiveRecord::Encryption::Errors::Configuration, "Missing Active Record encryption credential"
        )

        expect { verifier.call }.to raise_error(
          ActiveRecord::Encryption::Errors::Configuration, /Missing Active Record encryption credential/
        )
      end
    end

    context "when an encrypted column is NULL" do
      it "does not count it" do
        create(:childrens_barred_list_entry, trn: nil, national_insurance_number: nil)

        expect(verifier.call).to be_zero
      end
    end
  end
end
