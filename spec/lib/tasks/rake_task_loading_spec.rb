# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "rake task loading" do
  # load_tasks appends actions to tasks that already exist rather than replacing
  # them, so anything calling it while application code loads gives every task in
  # the app a second body, and every task then runs twice per invocation.
  it "leaves task bodies alone when application code is loaded" do
    Rails.application.load_tasks
    actions_before = Rake::Task["db:seed_role_codes"].actions.size

    load Rails.root.join("app/jobs/trim_sessions_job.rb")

    expect(Rake::Task["db:seed_role_codes"].actions.size).to eq actions_before
  end
end
