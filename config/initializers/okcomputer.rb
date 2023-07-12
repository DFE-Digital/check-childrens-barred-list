OkComputer.mount_at = "healthcheck"

OkComputer::Registry.register(
  "version",
  OkComputer::AppVersionCheck.new(env: "COMMIT_SHA"),
)

OkComputer.make_optional(%w[version])
