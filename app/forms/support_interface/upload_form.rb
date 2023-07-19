module SupportInterface
  class UploadForm
    include ActiveModel::Model

    attr_accessor :file

    validates :file, presence: true

    def save
      return false unless valid?

      CreateChildrensBarredListEntries.new(file.read).call
    end
  end
end
