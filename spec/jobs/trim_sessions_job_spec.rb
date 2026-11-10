# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe TrimSessionsJob do
  describe "#perform" do
    # The worker is a long-lived process and the job runs daily in it, so a
    # second run in the same process is the normal case, not an edge case.
    it "trims old sessions on every run in the same process, not only the first" do
      described_class.new.perform
      session = create_session(updated_at: 31.days.ago)

      described_class.new.perform

      expect(ActiveRecord::SessionStore::Session.exists?(session.id)).to be false
    end

    it "keeps sessions newer than the threshold" do
      session = create_session(updated_at: 1.day.ago)

      described_class.new.perform

      expect(ActiveRecord::SessionStore::Session.exists?(session.id)).to be true
    end

    it "gives the trim task no extra bodies however often it runs" do
      described_class.new.perform
      actions_before = Rake::Task["db:sessions:trim"].actions.size

      2.times { described_class.new.perform }

      expect(Rake::Task["db:sessions:trim"].actions.size).to eq actions_before
    end
  end

  def create_session(updated_at:)
    session = ActiveRecord::SessionStore::Session.create!(session_id: SecureRandom.hex, data: {})
    session.update_column(:updated_at, updated_at)
    session
  end
end
