module SupportInterface
  class UploadsController < ApplicationController
    def new
      @upload_form = UploadForm.new
    end

    def create
      @upload_form = UploadForm.new(upload_form_params)
      if @upload_form.save
        redirect_to support_interface_upload_success_path
      else
        render :new
      end
    end

    private

    def upload_form_params
      params.fetch(:support_interface_upload_form, {}).permit(:file)
    end
  end
end
