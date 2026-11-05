require "rake"

class TrimSessionsJob < ApplicationJob
  def perform
    Rails.application.load_tasks
    Rake::Task['db:sessions:trim'].invoke
  end
end
