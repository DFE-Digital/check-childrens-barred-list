class AddUnaccentExtension < ActiveRecord::Migration[7.0]
  UNACCENT_EXTENSION = "unaccent".freeze

  def up
    enable_extension(UNACCENT_EXTENSION) unless extensions.include?(UNACCENT_EXTENSION)
  end

  def down
    disable_extension(UNACCENT_EXTENSION) if extensions.include?(UNACCENT_EXTENSION)
  end
end
