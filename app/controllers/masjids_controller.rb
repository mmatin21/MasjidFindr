class MasjidsController < ApplicationController
  def index
    begin
      # Fetch masjids from the GraphQL API
      @masjids_data = GraphQlService.fetch_masjids

      # Check if the API returned an unauthorized error
      if @masjids_data['errors']
        api_errors = @masjids_data['errors'].map { |error| error['message'] }.join(", ")
        Rails.logger.error("GraphQL API Error: #{api_errors}")
        flash[:alert] = "Error fetching masjids: #{api_errors}"
        @masjids = [] # Return an empty array so the view can handle it gracefully
      else
        @masjids = @masjids_data['data']['masjids']
      end

    rescue StandardError => e
      Rails.logger.error("Unexpected Error: #{e.message}")
      flash[:notice] = "An unexpected error occurred while fetching masjids. Please try again later."
      @masjids = [] # Return an empty array as a fallback
    end
  end

  def show
    begin
      # Fetch the fundraisers for the selected masjid
      @masjid_id = params[:id]
      @fundraisers_data = GraphQlService.fetch_fundraisers_for_masjid(@masjid_id)
      @events_data = GraphQlService.fetch_events_for_masjid(@masjid_id)
      @prayers_data = GraphQlService.fetch_prayers_for_masjid(@masjid_id)
      @masjid_data = GraphQlService.fetch_masjid_by_id(@masjid_id)

      @fundraisers = @fundraisers_data['data']['fundraisers']
      @events = @events_data['data']['events']
      @prayers = @prayers_data['data']['prayers']

      @masjid_name = @masjid_data['data']['masjidById'][0]['name']
      @active_section = 'prayers'
      Rails.logger.debug "Params: #{params}"

      Rails.logger.debug "API Data: #{@events_data}"
      Rails.logger.debug "API Data: #{@prayers_data}"



      # Check if the API returned an unauthorized error
      if @fundraisers_data['errors']
        api_errors = @fundraisers_data['errors'].map { |error| error['message'] }.join(", ")
        Rails.logger.error("GraphQL API Error: #{api_errors}")
        flash[:alert] = "Error fetching fundraisers: #{api_errors}"
        @fundraisers = [] # Return an empty array so the view can handle it gracefully
      else
        @fundraisers = @fundraisers_data['data']['fundraisers']
      end

    rescue StandardError => e
      Rails.logger.error("Unexpected Error: #{e.message}")
      flash[:notice] = "An unexpected error occurred while fetching fundraisers. Please try again later."
      @fundraisers = [] # Return an empty array as a fallback
    end
  end
end
