# frozen_string_literal: true

class SearchesController < ApplicationController
  def new
    @search_form = SearchForm.new
  end

  def show
    @search_form = SearchForm.new(search_params)

    if @search_form.valid?
      @result = OpenStruct.new(last_name: search_params[:last_name])
    else
      render :new
    end
  end

  private

  def search_params
    params.require(:search_form).permit(:last_name)
  end
end
