require "rails_helper"

# Key derivation moved from SHA-1 to SHA-256, which no ciphertext records, so a
# silent revert of the configuration would not surface until rows stopped
# decrypting in production. These assert the intended state directly.
RSpec.describe "Active Record encryption configuration" do
  let(:config) { ActiveRecord::Encryption.config }

  it "derives keys with SHA-256" do
    expect(config.hash_digest_class).to eq OpenSSL::Digest::SHA256
  end

  # support_sha1_for_non_deterministic_encryption is a writer with no reader: it
  # appends a previous scheme. Assert what it buys instead of whether it was set.
  it "still reads non-deterministic columns written before the change" do
    dsi_user = create(:dsi_user, first_name: "Steven")
    write_under_sha1(dsi_user, :first_name, "Steven")

    expect(dsi_user.reload.first_name).to eq "Steven"
  end

  it "gives non-deterministic columns a SHA-1 fallback" do
    aggregate_failures do
      expect(DsiUser.type_for_attribute(:first_name).previous_types).not_to be_empty
      expect(ChildrensBarredListEntry.type_for_attribute(:trn).previous_types).not_to be_empty
    end
  end

  it "gives the deterministic columns no SHA-1 fallback of their own" do
    aggregate_failures do
      Pii::DETERMINISTIC_ATTRIBUTES.each do |name, attributes|
        attributes.each do |attribute|
          expect(name.constantize.type_for_attribute(attribute).previous_types)
            .to be_empty, "expected #{name}##{attribute} to have no previous types"
        end
      end
    end
  end

  # These are named rather than derived, so the specs have to be what keeps them
  # honest. An attribute added to a model, or its determinism changed, would
  # otherwise be silently left on the old digest.
  describe "the named attribute lists" do
    let(:declared) do
      Pii::ENCRYPTED_ATTRIBUTES.keys.index_with { |name| name.constantize.encrypted_attributes.to_a }
    end

    it "covers every encrypted attribute the models declare" do
      expect(Pii::ENCRYPTED_ATTRIBUTES.transform_values(&:sort))
        .to eq declared.transform_values(&:sort)
    end

    # The lists name models as well as attributes, so a newly encrypted model
    # would otherwise be missed entirely rather than caught by the spec above.
    # Only models that own their table count: FailedChildrensBarredListEntry
    # inherits its encryption from the model whose rows it describes.
    it "covers every model that declares an encrypted attribute" do
      Rails.autoloaders.main.eager_load_dir(Rails.root.join("app/models"))
      encrypted_models = ApplicationRecord.descendants.select do |model|
        model.base_class == model && model.encrypted_attributes.present?
      end

      expect(Pii::MODEL_NAMES).to match_array(encrypted_models.map(&:name))
    end

    it "marks exactly the attributes the models treat as deterministic" do
      deterministic = declared.to_h do |name, attributes|
        model = name.constantize
        [name, attributes.select { |a| model.type_for_attribute(a).deterministic? }]
      end

      expect(Pii::DETERMINISTIC_ATTRIBUTES.transform_values(&:sort))
        .to eq(deterministic.reject { |_, attributes| attributes.empty? }.transform_values(&:sort))
    end
  end
end
