# frozen_string_literal: true
namespace :pii do
  desc "Rewrite every encrypted attribute under the current key-derivation digest"
  task :re_encrypt, %i[resume_model resume_id] => :environment do |_task, args|
    Pii::ReEncryptor.new(
      resume_model: args[:resume_model],
      resume_id: args[:resume_id],
      logger: Logger.new($stdout)
    ).call
  end

  desc "Report rows that cannot be read under the current key-derivation digest alone"
  task verify: :environment do
    unreadable = Pii::Verifier.new(logger: Logger.new($stdout)).call

    abort("pii:verify found #{unreadable} unreadable attributes") if unreadable.positive?
  end
end
