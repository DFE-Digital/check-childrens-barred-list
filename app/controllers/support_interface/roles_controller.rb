module SupportInterface
  class RolesController < SupportInterfaceController
    def index
      @roles = Role.all
    end

    def new
      @role = Role.new
    end

    def create
      @role = Role.create!(role_params)
      redirect_to support_interface_roles_path
    end

    private

    def role_params
      params.require(:role).permit(:code, :enabled, :internal ).tap do |rp|
        rp[:enabled] = ActiveRecord::Type::Boolean.new.cast(rp[:enabled])
      end
    end
  end
end
