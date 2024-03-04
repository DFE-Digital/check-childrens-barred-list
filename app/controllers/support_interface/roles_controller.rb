module SupportInterface
  class RolesController < SupportInterfaceController
    def index
      @roles = Role.all
    end
  end
end
