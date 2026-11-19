require "rails_helper"
require "rake"

# The runbook gates the irreversible cleanup on pii:verify's exit status, so the
# abort is load-bearing rather than a convenience.
RSpec.describe "pii rake tasks" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before { Rake::Task[task_name].reenable }

  describe "pii:verify" do
    let(:task_name) { "pii:verify" }

    context "when every row reads under the current digest" do
      it "completes without aborting" do
        create(:dsi_user)

        expect { Rake::Task[task_name].invoke }.not_to raise_error
      end
    end

    context "when a row still holds SHA-1 ciphertext" do
      it "aborts, so a caller checking the exit status stops" do
        dsi_user = create(:dsi_user)
        write_under_sha1(dsi_user, :email, "legacy@example.com")

        expect { Rake::Task[task_name].invoke }.to raise_error(SystemExit)
      end
    end
  end

  describe "pii:re_encrypt" do
    let(:task_name) { "pii:re_encrypt" }

    it "converts the rows it finds" do
      dsi_user = create(:dsi_user)
      write_under_sha1(dsi_user, :email, dsi_user.email)

      Rake::Task[task_name].invoke

      expect(readable_under_sha256?(dsi_user, :email)).to be true
    end

    it "passes the resume arguments through to the re-encryptor" do
      expect { Rake::Task[task_name].invoke("Widget", "1") }
        .to raise_error(ArgumentError, /Widget is not one of/)
    end
  end
end
