module SupportInterface
  class RolesController < SupportInterfaceController
    def index
      @roles = Role.all
    end

    def new
      @role = Role.new
    end

    def create
      @role = Role.new(role_params)
      if @role.save
        redirect_to support_interface_roles_path
      else
        render :new
      end
    end

    def edit
      @role = Role.find(params[:id])
    end

    def update
      @role = Role.find(params[:id])
      if @role.update(role_params)
        redirect_to support_interface_roles_path
      else
        render :edit
      end
    end

    private

    def role_params
      params.require(:role).permit(:code, :enabled, :internal).tap do |rp|
        rp[:enabled] = ActiveRecord::Type::Boolean.new.cast(rp[:enabled])
        rp[:internal] ||= false
      end
    end
  end
end
