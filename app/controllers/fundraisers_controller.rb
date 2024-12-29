class FundraisersController < ApplicationController
  def show
    begin
      # Fetch the fundraisers for the selected masjid

      @fundraiser_id = params[:id]
      @fundraiser_data = GraphQlService.fetch_fundraisers_by_id(params[:id])
      Rails.logger.debug "Masjid: #{params}"

      # Check if the API returned an unauthorized error
      if @fundraiser_data['errors']
        api_errors = @fundraiser_data['errors'].map { |error| error['message'] }.join(", ")
        Rails.logger.error("GraphQL API Error: #{api_errors}")
        flash[:alert] = "Error fetching fundraisers: #{api_errors}"
        @fundraiser = [] # Return an empty array so the view can handle it gracefully
      else
        @fundraiser = @fundraiser_data['data']['fundraisers']
      end
    rescue StandardError => e
      Rails.logger.error("Unexpected Error: #{e.message}")
      flash[:notice] = "An unexpected error occurred while fetching fundraisers. Please try again later."
      @fundraiser = [] # Return an empty array as a fallback
    end
  end
end
