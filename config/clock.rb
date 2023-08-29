require 'clockwork'
require 'active_support/time' # Allow numeric durations (eg: 1.minutes)

module Clockwork
  every(1.day, "DeleteUnconfirmedEntries.perform_later", at: "00:00")
end
