# frozen_string_literal: true

class SearchesController < ApplicationController
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
    params.require(:search_form).permit(:last_name)
  end

  def any_records?
    ChildrensBarredListEntry.includes_record?(
      last_name: search_params[:last_name],
    )
  end
end
