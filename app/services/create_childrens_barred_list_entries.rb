require "csv"

class CreateChildrensBarredListEntries
  TITLES_REGEX = /^(mr|mrs|miss|ms|dr|prof)\.? /i

  attr_reader :failed_entries, :upload_file_hash

  def initialize(raw_data)
    @raw_data = raw_data
    @upload_file_hash = Digest::SHA256.hexdigest(raw_data)
    @failed_entries = []
  end

  def call
    CSV
      .parse(@raw_data, encoding: "ISO8859-1:utf-8")
      .each do |row|
        entry = ChildrensBarredListEntry.create(
          trn: pad_trn(row[0]),
          last_name: format_names(row[1]),
          first_names: format_names(row[2]),
          date_of_birth: format_date_of_birth(row[3]),
          national_insurance_number: row[4],
          upload_file_hash:,
        )

        @failed_entries << entry unless entry.persisted?
      end
  end

  def pad_trn(trn)
    return trn if trn.blank?

    trn.rjust(7, "0")
  end

  def format_names(names)
    return if names.blank?

    names.strip!
    names.gsub!(TITLES_REGEX, "")
    names.downcase.split(" ").map(&:capitalize).join(" ")
  end

  def format_date_of_birth(date_of_birth)
    return if date_of_birth.blank?

    Date.parse(date_of_birth).to_fs(:db)
  rescue Date::Error
    nil
  end
end
