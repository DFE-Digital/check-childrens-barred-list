module BarredListEntries
  # Prints each entry holding plaintext that search can't find, then counts.
  #
  # Prints counts and row ids only, never a value.
  class UnfindableReport
    CIPHERTEXT_PATTERN = UnfindableEntries::CIPHERTEXT_PATTERN

    def initialize(output: $stdout, entries: UnfindableEntries.new)
      @output = output
      @entries = entries
    end

    def call
      output.puts "report: read only, changes nothing"
      unfindable = []
      unreadable = []
      entries.each do |found|
        case found
        when UnfindableEntries::Unfindable then unfindable << report(found)
        when UnfindableEntries::Unreadable then unreadable << report_unreadable(found)
        end
      end

      print_counts(unfindable, unreadable)
    end

    private

    attr_reader :output, :entries

    def report(unfindable)
      output.puts "unfindable entry: #{unfindable.id} (confirmed: #{unfindable.confirmed}, " \
                  "uploaded before confirmation: #{unfindable.uploaded_before_confirmation})"
      unfindable
    end

    def report_unreadable(unreadable)
      output.puts "unreadable entry: #{unreadable.id}"
      unreadable
    end

    def print_counts(unfindable, unreadable)
      counts = {
        entries: ChildrensBarredListEntry.count,
        entries_holding_plaintext: ChildrensBarredListEntry.where(holding_plaintext).count,
        unreadable_entries: unreadable.size,
        unfindable_entries: unfindable.size,
        confirmed_unfindable_entries: unfindable.count(&:confirmed),
        unfindable_entries_uploaded_before_confirmation: unfindable.count(&:uploaded_before_confirmation)
      }
      counts.each { |name, count| output.puts "#{name}: #{count}" }
      counts
    end

    def holding_plaintext
      ChildrensBarredListEntry.encrypted_attributes.map { |attribute|
        "#{ChildrensBarredListEntry.connection.quote_column_name(attribute)} NOT LIKE '#{CIPHERTEXT_PATTERN}'"
      }.join(" OR ")
    end
  end
end
