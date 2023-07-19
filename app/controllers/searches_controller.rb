# frozen_string_literal: true

class SearchesController < ApplicationController
  def new
  end

  def show
    @result = OpenStruct.new(last_name: search_params[:last_name])
  end

  private

  def search_params
    params.permit(:last_name)
  end
end
