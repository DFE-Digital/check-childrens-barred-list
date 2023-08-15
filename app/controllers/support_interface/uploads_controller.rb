module SupportInterface
  class UploadsController < ApplicationController
    def new
      @upload_form = UploadForm.new
    end

    def create
      @upload_form = UploadForm.new(upload_form_params)
      if @upload_form.save
        redirect_to support_interface_upload_preview_path(
          upload_file_hash: @upload_form.upload_file_hash
        )
      else
        render :new
      end
    end

    def preview
      @upload_file_hash = upload_file_hash_param
      @unconfirmed_entries = ChildrensBarredListEntry
        .where(confirmed: false, upload_file_hash: upload_file_hash_param)
    end

    def confirm
      if ConfirmChildrensBarredListEntries.new.call(upload_file_hash_param)
        redirect_to support_interface_upload_success_path
      else
        render :preview
      end
    end

    private

    def upload_form_params
      params.fetch(:support_interface_upload_form, {}).permit(:file)
    end

    def upload_file_hash_param
      params[:upload_file_hash]
    end
  end
end
