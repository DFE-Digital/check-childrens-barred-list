require "rails_helper"

RSpec.describe Pii::ReEncryptor do
  subject(:re_encryptor) { described_class.new(logger: Logger.new(File::NULL)) }

  describe "#call" do
    context "when rows were written under SHA-1" do
      it "makes every encrypted attribute of a barred list entry readable under SHA-256 alone" do
        entry = create(:childrens_barred_list_entry, trn: "1234567", national_insurance_number: "AB123456C")
        plaintext = Pii::ENCRYPTED_ATTRIBUTES.fetch("ChildrensBarredListEntry").index_with { |a| entry.public_send(a) }
        plaintext.each { |attribute, value| write_under_sha1(entry, attribute, value) }

        re_encryptor.call

        aggregate_failures do
          plaintext.each do |attribute, value|
            expect(readable_under_sha256?(entry, attribute)).to be(true), "expected #{attribute} readable"
            expect(entry.reload.public_send(attribute)).to eq value
          end
        end
      end

      # dfe-analytics tracks DsiUser writes by reading each attribute's old value
      # through the model's type, which raises on SHA-1 deterministic ciphertext.
      it "converts DsiUser, whose writes dfe-analytics tracks" do
        dsi_user = create(:dsi_user, email: "dsi@example.com", first_name: "Steven")
        write_under_sha1(dsi_user, :email, "dsi@example.com")
        write_under_sha1(dsi_user, :first_name, "Steven")

        re_encryptor.call

        aggregate_failures do
          expect(readable_under_sha256?(dsi_user, :email)).to be true
          expect(readable_under_sha256?(dsi_user, :first_name)).to be true
          expect(dsi_user.reload.email).to eq "dsi@example.com"
        end
      end

      it "converts SearchLog" do
        search_log = create(:search_log, dsi_user: create(:dsi_user), last_name: "Doe", date_of_birth: "1980-01-01")
        write_under_sha1(search_log, :last_name, "Doe")
        write_under_sha1(search_log, :date_of_birth, "1980-01-01")

        re_encryptor.call

        aggregate_failures do
          expect(readable_under_sha256?(search_log, :last_name)).to be true
          expect(readable_under_sha256?(search_log, :date_of_birth)).to be true
          expect(search_log.reload.last_name).to eq "Doe"
        end
      end

      it "spans more than one batch" do
        stub_const("#{described_class}::BATCH_SIZE", 2)
        dsi_users = create_list(:dsi_user, 5)
        dsi_users.each { |dsi_user| write_under_sha1(dsi_user, :email, dsi_user.email) }

        re_encryptor.call

        expect(dsi_users).to all(satisfy { |dsi_user| readable_under_sha256?(dsi_user, :email) })
      end
    end

    context "when a row was already converted" do
      it "leaves the value unchanged" do
        dsi_user = create(:dsi_user, email: "converted@example.com")

        expect { re_encryptor.call }.not_to(change { dsi_user.reload.email })
      end

      it "does not touch updated_at" do
        entry = create(:childrens_barred_list_entry)
        entry.update_column(:updated_at, 3.days.ago)

        expect { re_encryptor.call }.not_to(change { entry.reload.updated_at })
      end
    end

    context "when an encrypted column is NULL" do
      it "leaves it NULL rather than encrypting a nil" do
        entry = create(:childrens_barred_list_entry, trn: nil)

        re_encryptor.call

        expect(entry.reload.read_attribute_before_type_cast(:trn)).to be_nil
      end
    end

    context "with a resume cursor" do
      it "skips rows before the cursor and converts the rest" do
        first, second = create_list(:dsi_user, 2)
        [first, second].each { |dsi_user| write_under_sha1(dsi_user, :email, dsi_user.email) }

        described_class.new(resume_model: "DsiUser", resume_id: second.id, logger: Logger.new(File::NULL)).call

        aggregate_failures do
          expect(readable_under_sha256?(first, :email)).to be false
          expect(readable_under_sha256?(second, :email)).to be true
        end
      end

      it "raises naming the models when given an unknown one" do
        expect { described_class.new(resume_model: "Widget", resume_id: 1) }
          .to raise_error(ArgumentError, /Widget is not one of/)
      end

      it "raises when given an id without the model it belongs to" do
        expect { described_class.new(resume_id: 5) }
          .to raise_error(ArgumentError, /a resume id needs a resume model/)
      end

      it "skips models before the one the cursor names" do
        dsi_user = create(:dsi_user)
        entry = create(:childrens_barred_list_entry)
        write_under_sha1(dsi_user, :email, dsi_user.email)
        write_under_sha1(entry, :last_name, entry.last_name)

        described_class.new(resume_model: "ChildrensBarredListEntry", resume_id: entry.id, logger: Logger.new(File::NULL)).call

        aggregate_failures do
          expect(readable_under_sha256?(dsi_user, :email)).to be false
          expect(readable_under_sha256?(entry, :last_name)).to be true
        end
      end
    end

    # The verifier pins this too. If the writer inherits a global true,
    # handle_deserialize_error returns the raw ciphertext instead of raising, the
    # SHA-1 fallback never runs, and that ciphertext gets encrypted again as
    # though it were plaintext.
    context "when support_unencrypted_data is enabled globally" do
      it "still reads a SHA-1 row through the SHA-1 type" do
        dsi_user = create(:dsi_user)
        write_under_sha1(dsi_user, :email, "legacy@example.com")
        allow(ActiveRecord::Encryption.config).to receive(:support_unencrypted_data).and_return(true)

        re_encryptor.call

        expect(dsi_user.reload.email).to eq "legacy@example.com"
      end

      # The model's own type would hand this back as plaintext and the run would
      # encrypt it again, which verification would then read as fine.
      it "stops on a non-deterministic value readable under neither digest rather than encrypting it again" do
        dsi_user = create(:dsi_user)
        write_raw(dsi_user, :first_name, "not ciphertext under any key")
        allow(ActiveRecord::Encryption.config).to receive(:support_unencrypted_data).and_return(true)

        aggregate_failures do
          expect { re_encryptor.call }
            .to raise_error(ActiveRecord::Encryption::Errors::Base, /DsiUser##{dsi_user.id}/)
          expect(dsi_user.reload.read_attribute_before_type_cast(:first_name)).to eq "not ciphertext under any key"
        end
      end
    end

    context "when a value is readable under neither digest" do
      it "raises naming the row and a cursor that skips only that row" do
        dsi_user = create(:dsi_user)
        write_raw(dsi_user, :email, "not ciphertext under any key")

        expect { re_encryptor.call }
          .to raise_error(ActiveRecord::Encryption::Errors::Base,
                          /DsiUser##{dsi_user.id}.*pii:re_encrypt\[DsiUser,#{dsi_user.id + 1}\]/)
      end

      # Rolling back the batch would leave every row between the last logged
      # cursor and this one on SHA-1, and skipping past it would lose them.
      it "keeps the rows before it in the batch and leaves the ones after it" do
        before_it, bad, after_it = create_list(:dsi_user, 3)
        [before_it, after_it].each { |dsi_user| write_under_sha1(dsi_user, :email, dsi_user.email) }
        write_raw(bad, :email, "not ciphertext under any key")

        expect { re_encryptor.call }.to raise_error(ActiveRecord::Encryption::Errors::Base)

        aggregate_failures do
          expect(readable_under_sha256?(before_it, :email)).to be true
          expect(readable_under_sha256?(after_it, :email)).to be false
        end
      end
    end

    # The unique index on names and date of birth covers ciphertext, so it lets
    # the same person in twice under different digests. Converting the second
    # copy then collides with the first.
    context "when converting a row duplicates one already under SHA-256" do
      it "raises naming the row and rolls back its batch, which Postgres has aborted" do
        original = create(:childrens_barred_list_entry, first_names: "Jane", last_name: "Doe",
                                                        date_of_birth: "1980-01-01", trn: "1234567")
        write_under_sha1(original, :trn, "1234567")
        duplicate = create(:childrens_barred_list_entry, first_names: "Janet",
                                                         last_name: "Doe",
                                                         date_of_birth: "1980-01-01")
        write_under_sha1(duplicate, :first_names, "Jane")
        write_under_sha1(duplicate, :last_name, "Doe")
        write_under_sha1(duplicate, :date_of_birth, "1980-01-01")

        aggregate_failures do
          expect { re_encryptor.call }
            .to raise_error(ActiveRecord::RecordNotUnique, /ChildrensBarredListEntry##{duplicate.id}.*rolled back/m)
          expect(readable_under_sha256?(original, :trn)).to be false
        end
      end
    end
  end
end
