require "csv"

class CreateChildrensBarredListEntries
  TITLES_REGEX = /^(mr|mrs|miss|ms|dr|prof)\.? /i

  def initialize(raw_data)
    @raw_data = raw_data
  end

  def call
    CSV
      .parse(@raw_data)
      .each do |row|
        entry = ChildrensBarredListEntry.find_or_initialize_by(
          last_name: format_names(row[1]),
          first_names: format_names(row[2]),
          date_of_birth: row[3],
        )
        next if entry.trn.present? && entry.national_insurance_number.present?

        entry.update!(
          trn: pad_trn(row[0]),
          national_insurance_number: row[4],
        )
      end
  end

  def pad_trn(trn)
    return trn if trn.blank?

    trn.rjust(7, "0")
  end

  def format_names(names)
    names.strip!
    names.gsub!(TITLES_REGEX, "")
    names.split(" ").map(&:capitalize).join(" ")
  end
end
