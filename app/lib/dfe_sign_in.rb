require "hosting_environment"

class DfESignIn
  def self.bypass?
    HostingEnvironment.test_environment? && ENV["BYPASS_DSI"] == "true"
  end
end
