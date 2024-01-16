class FailedChildrensBarredListEntries
  EXPIRES = 1.hour.to_i

  def set(form)
    if form.failed_entries.present?
      redis.set(
        entries_key(form.upload_file_hash),
        form.failed_entries.to_json,
        ex: EXPIRES
      )
    end
  end

  def get(upload_file_hash)
    entries = redis.get(entries_key(upload_file_hash))
    JSON.parse(entries).map { |entry| FailedChildrensBarredListEntry.new(entry) } if entries.present?
  end

  def clear(upload_file_hash)
    redis.del(entries_key(upload_file_hash))
  end

  def entries_key(upload_file_hash)
    "cbl-failed-entries-#{upload_file_hash}"
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))
  end
end
