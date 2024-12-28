class FundraisersController < ApplicationController
  def show
    @fundraiser_id = params[:id]
    @fundraiser_data = GraphQlService.fetch_fundraisers_by_id(params[:id])
    @fundraiser = @fundraiser_data['data']['fundraiserById'][0]

    Rails.logger.debug "Fundraiser: #{params}" 

  end
end
