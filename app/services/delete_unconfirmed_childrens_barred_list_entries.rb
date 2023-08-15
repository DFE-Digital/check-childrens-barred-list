class DeleteUnconfirmedChildrensBarredListEntries
  def call(upload_file_hash)
    ChildrensBarredListEntry
      .where(confirmed: false, upload_file_hash:)
      .delete_all
  end
end
