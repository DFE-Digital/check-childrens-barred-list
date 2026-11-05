require "rake"

class TrimSessionsJob < ApplicationJob
  TASK_NAME = "db:sessions:trim".freeze

  def perform
    # load_tasks appends to tasks that already exist, so loading on every run
    # would give the task another body each day the worker stays up.
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK_NAME)

    # invoke runs a task once per process and is a no-op after that, and the
    # worker is a long-lived process, so without this only the first run trims.
    Rake::Task[TASK_NAME].reenable
    Rake::Task[TASK_NAME].invoke
  end
end
