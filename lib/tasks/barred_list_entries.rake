# frozen_string_literal: true

# Prints counts and row ids only, never a value. See
# docs/unfindable-barred-list-entries.md for what each line means.
namespace :barred_list_entries do
  desc "List barred list entries holding plaintext that search can't find. Read only, and quick"
  task unfindable: :environment do
    $stdout.sync = true # so the lines printed so far survive if the pod kills the process
    BarredListEntries::UnfindableReport.new.call
  end
end
