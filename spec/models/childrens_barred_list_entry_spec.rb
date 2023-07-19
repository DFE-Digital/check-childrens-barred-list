require "rails_helper"

RSpec.describe ChildrensBarredListEntry, type: :model do
  it { is_expected.to validate_presence_of(:first_names) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:date_of_birth) }
end
