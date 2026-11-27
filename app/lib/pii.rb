module Pii
  # Every encrypted column in the application. The set is fixed, so it is named
  # here rather than rediscovered from the models on each row, and the conversion
  # and the check that gates it agree by construction.
  #
  # spec/config/encryption_spec.rb asserts both of these still match what the
  # models declare, so an attribute added or its determinism changed cannot drift
  # out of scope unnoticed.
  #
  # The order is the order the conversion runs in: sign-in, then search, then
  # the search log, which nothing in the application reads back and which is
  # the largest table.
  ENCRYPTED_ATTRIBUTES = {
    "DsiUser" => %i[email first_name last_name],
    "ChildrensBarredListEntry" => %i[
      date_of_birth
      first_names
      last_name
      national_insurance_number
      searchable_last_name
      trn
    ],
    "SearchLog" => %i[date_of_birth last_name]
  }.freeze

  # The ones a lookup can silently miss on, and the only ones the conversion has
  # to read by hand.
  DETERMINISTIC_ATTRIBUTES = {
    "DsiUser" => %i[email],
    "ChildrensBarredListEntry" => %i[date_of_birth first_names last_name searchable_last_name],
    "SearchLog" => %i[date_of_birth last_name]
  }.freeze

  MODEL_NAMES = ENCRYPTED_ATTRIBUTES.keys.freeze
end
