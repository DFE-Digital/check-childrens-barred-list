require "rails_helper"
require "rake"

RSpec.describe "barred_list_entries rake tasks" do
  # Other specs load the tasks too, and a second load_tasks gives every task a
  # second body, so these load them once into a Rake application of their own,
  # and re-enable each task for every example.
  before(:all) do
    previous = Rake.application
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
    @rake = Rake.application
  ensure
    Rake.application = previous
  end

  around do |example|
    previous = Rake.application
    Rake.application = @rake
    Rake.application.tasks.each(&:reenable)
    example.run
  ensure
    Rake.application = previous
  end

  let!(:plaintext) { create_plaintext_entry(first_names: "Jane", last_name: "Doe") }

  describe "barred_list_entries:unfindable" do
    it "prints the report once, changing nothing" do
      aggregate_failures do
        expect { Rake::Task["barred_list_entries:unfindable"].invoke }.to output(
          satisfy do |printed|
            printed.scan("report: read only").one? &&
              printed.include?("unfindable entry: #{plaintext.id} ") &&
              printed.include?("unfindable_entries: 1\n")
          end
        ).to_stdout
        expect(ChildrensBarredListEntry.exists?(plaintext.id)).to be true
      end
    end
  end

  describe "barred_list_entries:failed_searches" do
    it "prints the report once" do
      expect { Rake::Task["barred_list_entries:failed_searches"].invoke }.to output(
        satisfy do |printed|
          printed.scan("report: read only").one? &&
            printed.include?("failed searches for entry #{plaintext.id}: 0\n")
        end
      ).to_stdout
    end
  end
end
