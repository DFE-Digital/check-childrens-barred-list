require_relative "../../lib/ok_computer_checks/database_integrity_check"

OkComputer.mount_at = "healthcheck"

OkComputer::Registry.register(
  "version",
  OkComputer::AppVersionCheck.new(env: "COMMIT_SHA"),
)

OkComputer::Registry.register "postgresql", OkComputer::ActiveRecordCheck.new
OkComputer::Registry.register "database_integrity", OkComputerChecks::DatabaseIntegrityCheck.new

OkComputer.make_optional(%w[version])
