module SupportInterface
  class UploadForm
    include ActiveModel::Model

    attr_accessor :file, :failed_entries, :upload_file_hash

    validates :file, presence: true

    def save
      return false unless valid?

      service = CreateChildrensBarredListEntries.new(file.read)
      @upload_file_hash = service.upload_file_hash
      @failed_entries = service.failed_entries
      service.call
    rescue CSV::MalformedCSVError
      errors.add(:file, :invalid_csv)
      false
    end
  end
end
