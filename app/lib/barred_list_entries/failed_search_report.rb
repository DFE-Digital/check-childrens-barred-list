module BarredListEntries
  # Counts, for each entry holding plaintext that search can't find, the
  # logged searches for that person that returned no record: each one a user
  # told the person isn't on the list.
  #
  # search_logs has no index on the name or date, so each count reads the
  # whole table. That's why this runs apart from UnfindableReport.
  #
  # Approximate: the log holds the last name as typed, so only a few common
  # spellings of it are tried. Prints counts and row ids only, never a value.
  class FailedSearchReport
    def initialize(output: $stdout, entries: UnfindableEntries.new)
      @output = output
      @entries = entries
    end

    def call
      output.puts "report: read only, changes nothing"
      total = entries.grep(UnfindableEntries::Unfindable).sum { |unfindable| report(unfindable) }

      output.puts "failed_searches_for_unfindable_entries: #{total}"
      total
    end

    private

    attr_reader :output, :entries

    def report(unfindable)
      failed_searches = failed_searches_for(unfindable)
      output.puts "failed searches for entry #{unfindable.id}: #{failed_searches}"
      failed_searches
    end

    def failed_searches_for(unfindable)
      last_name = unfindable.last_name
      spellings = [last_name, last_name.downcase, last_name.upcase, last_name.capitalize].uniq

      SearchLog.where(last_name: spellings, date_of_birth: unfindable.date_of_birth, result_returned: false).count
    end
  end
end
