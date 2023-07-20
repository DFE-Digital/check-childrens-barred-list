# frozen_string_literal: true

class SearchesController < ApplicationController
  DOB_CONVERSION = {
    "date_of_birth(3i)" => "day",
    "date_of_birth(2i)" => "month",
    "date_of_birth(1i)" => "year",
  }.freeze

  def new
    @search_form = SearchForm.new
  end

  def show
    @search_form = SearchForm.new(search_params)

    if @search_form.valid?
      render :no_record unless any_records?
    else
      render :new
    end
  end

  private

  def search_params
    params
      .require(:search_form)
      .permit(:last_name, *DOB_CONVERSION.keys)
      .transform_keys do |key|
        DOB_CONVERSION.keys.include?(key) ? DOB_CONVERSION[key] : key
      end
  end

  def any_records?
    ChildrensBarredListEntry.includes_record?(
      last_name: search_params[:last_name],
    )
  end
end
