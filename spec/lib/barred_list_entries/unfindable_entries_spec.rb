require "rails_helper"

RSpec.describe BarredListEntries::UnfindableEntries do
  subject(:found) { described_class.new.to_a }

  let(:person) do
    { first_names: "Jane", last_name: "Doe", date_of_birth: "1980-01-01", trn: "1234567",
      national_insurance_number: "AB123456C" }
  end

  describe "#each" do
    context "with a plaintext entry and no other entry for the person" do
      it "yields it, with the plaintext search used" do
        plaintext = create_plaintext_entry(**person)

        expect(found).to contain_exactly(
          have_attributes(id: plaintext.id, confirmed: true, uploaded_before_confirmation: false,
                          last_name: "Doe", date_of_birth: "1980-01-01")
        )
      end
    end

    context "with a plaintext entry and a confirmed ciphertext copy" do
      it "yields nothing, as search finds the person through the copy" do
        create(:childrens_barred_list_entry, **person)
        create_plaintext_entry(**person)

        expect(found).to be_empty
      end
    end

    context "with a plaintext entry and an unconfirmed ciphertext copy" do
      it "yields it, as search only matches confirmed entries" do
        create(:childrens_barred_list_entry, **person, confirmed: false)
        plaintext = create_plaintext_entry(**person)

        expect(found.map(&:id)).to eq [plaintext.id]
      end
    end

    # Search ignores first names, so it finds the person through an entry
    # under other first names, such as a mis-encoded accent.
    context "with a plaintext entry and a confirmed entry under other first names" do
      it "yields nothing" do
        create(:childrens_barred_list_entry, **person, first_names: "Janet")
        create_plaintext_entry(**person)

        expect(found).to be_empty
      end
    end

    # What update_columns, or encrypting a plaintext row without saving it
    # through the model, leaves: ciphertext with no searchable_last_name.
    context "with a ciphertext entry that has no searchable_last_name" do
      let!(:entry) do
        create(:childrens_barred_list_entry, **person).tap { |entry| store_raw(entry, :searchable_last_name, nil) }
      end

      it "yields it, as search can't match its row" do
        expect(found.map(&:id)).to eq [entry.id]
      end

      # Only a decrypted date of birth matches another entry's, so this also
      # shows the search uses the value read, not the stored ciphertext.
      context "with a confirmed entry under other first names" do
        it "yields nothing" do
          create(:childrens_barred_list_entry, **person, first_names: "Janet")

          expect(found).to be_empty
        end
      end
    end

    context "with a ciphertext entry whose searchable_last_name is plaintext" do
      it "yields it, as search can't match its row" do
        entry = create(:childrens_barred_list_entry, **person)
        store_raw(entry, :searchable_last_name, "doe")

        expect(found.map(&:id)).to eq [entry.id]
      end
    end

    context "with an entry holding plaintext in its date of birth only" do
      it "yields it, as search can't match a plaintext date of birth" do
        entry = create(:childrens_barred_list_entry, **person)
        store_raw(entry, :date_of_birth, "1980-01-01")

        expect(found.map(&:id)).to eq [entry.id]
      end
    end

    context "with plaintext in its TRN only" do
      it "yields nothing, as search finds its own row" do
        entry = create(:childrens_barred_list_entry, **person)
        store_raw(entry, :trn, "1234567")

        expect(found).to be_empty
      end
    end

    # upload_file_hash arrived with confirmed and wasn't backfilled.
    context "with unconfirmed plaintext entries" do
      it "says which were uploaded before confirmation existed" do
        before_confirmation = create_plaintext_entry(**person, confirmed: false)
        before_confirmation.update_columns(upload_file_hash: nil)
        abandoned_upload = create_plaintext_entry(first_names: "John", last_name: "Smith", confirmed: false)
        confirmed_without_hash = create_plaintext_entry(first_names: "Ann", last_name: "Lee")
        confirmed_without_hash.update_columns(upload_file_hash: nil)

        expect(found).to contain_exactly(
          have_attributes(id: before_confirmation.id, uploaded_before_confirmation: true),
          have_attributes(id: abandoned_upload.id, uploaded_before_confirmation: false),
          have_attributes(id: confirmed_without_hash.id, uploaded_before_confirmation: false)
        )
      end
    end

    context "with an entry whose last name no configured key can read" do
      it "yields it as unreadable, and carries on" do
        entry = create(:childrens_barred_list_entry, **person)
        store_raw(entry, :date_of_birth, "1980-01-01")
        store_under_unknown_key(entry, :last_name, "Doe")
        plaintext = create_plaintext_entry(first_names: "John", last_name: "Smith", date_of_birth: "1970-05-05")

        expect(found).to contain_exactly(described_class::Unreadable.new(id: entry.id),
                                         have_attributes(id: plaintext.id))
      end
    end

    # Anything else is a fault in the report or the database, not an entry it
    # couldn't read, so it stops the report rather than being listed.
    it "lets any other error through" do
      create_plaintext_entry(**person)
      allow(ChildrensBarredListEntry).to receive(:search).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect { found }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    # The values are kept for counting failed searches, so nothing that
    # prints one of these may print them.
    it "keeps values out of an unfindable entry's inspect" do
      create_plaintext_entry(**person)

      expect(found.first.inspect).not_to include("Doe", "1980")
    end

    # It runs against production. Sentry keeps the SQL of recent queries as
    # breadcrumbs, so values have to travel as binds.
    it "only reads, takes no lock, and keeps values out of the SQL text" do
      create_plaintext_entry(**person)

      sql = queries_during { found }

      aggregate_failures do
        expect(sql).not_to include(a_string_matching(/\A\s*(INSERT|UPDATE|DELETE)/i))
        expect(sql).not_to include(a_string_matching(/FOR UPDATE/))
        %w[Jane Doe doe 1980-01-01].each { |value| expect(sql.join("\n")).not_to include(value) }
        expect(sql.join("\n")).not_to include('"p":')
      end
    end
  end
end
