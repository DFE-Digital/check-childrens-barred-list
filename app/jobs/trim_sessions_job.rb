require "rake"
Rails.application.load_tasks

class TrimSessionsJob < ApplicationJob
  def perform
    Rake::Task['db:sessions:trim'].invoke
  end
end
