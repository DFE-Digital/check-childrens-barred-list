class ConfirmChildrensBarredListEntries
  def call(upload_file_hash)
    ChildrensBarredListEntry
      .where(confirmed: false, upload_file_hash:)
      .update_all(
        confirmed: true,
        confirmed_at: Time.zone.now,
      )
  end
end
