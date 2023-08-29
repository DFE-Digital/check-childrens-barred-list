class DeleteUnconfirmedEntriesWorker < ApplicationJob
  def perform
    ChildrensBarredListEntry
      .where(confirmed: false)
      .destroy_all
  end
end
