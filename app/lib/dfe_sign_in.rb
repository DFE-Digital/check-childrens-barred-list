require "hosting_environment"

class DfESignIn
  def self.bypass?
    # Review apps get ephemeral per-PR hostnames that real DfE Sign-in can't serve, so they always
    # use the developer strategy. Other test environments opt in explicitly via BYPASS_DSI.
    HostingEnvironment.review? || (HostingEnvironment.test_environment? && ENV["BYPASS_DSI"] == "true")
  end
end
