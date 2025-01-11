require 'geocoder'
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

      Rails.logger.debug "Query params: #{params[:query]}"
      @masjids = if params[:query].present?
        # Get coordinates from query using geocoder
        Rails.logger.debug "Getting coordinates for query: #{params[:query]}"
        begin
          coordinates = Geocoder.coordinates(params[:query])
          Rails.logger.debug "Coordinates returned: #{coordinates.inspect}"
          if coordinates.nil?
            Rails.logger.error "No coordinates returned for query: #{params[:query]}"
          end
        rescue Geocoder::Error => e
          Rails.logger.error "Geocoding error: #{e.message}"
          coordinates = nil
        end

        if coordinates
          Rails.logger.debug "Found coordinates, filtering masjids"
          # Filter masjids near the coordinates
          @masjids_data['data']['masjids'].select do |masjid|
            # Calculate distance between coordinates
            Rails.logger.debug "Calculating distance for masjid: #{masjid['name']}"
            Rails.logger.debug "Masjid coordinates: [#{masjid['latitude']}, #{masjid['longitude']}]"

            distance = Geocoder::Calculations.distance_between(
              coordinates,
              [masjid['latitude'].to_f, masjid['longitude'].to_f]
            )
            Rails.logger.debug "Distance calculated: #{distance} miles"
            # Return masjids within 50 miles
            distance <= 50
          end
        else
          Rails.logger.debug "No coordinates found, returning all masjids"
          @masjids_data['data']['masjids']
        end
      else
        Rails.logger.debug "No query provided, returning all masjids"
        @masjids_data['data']['masjids']
      end
      Rails.logger.debug "Final masjids count: #{@masjids.count}"

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
      masjid_data = GraphQlService.fetch_masjid_by_id(@masjid_id)
      @masjid_name = masjid_data['data']['masjidById'][0]['name']
      @masjid_stripe_account_id = masjid_data['data']['masjidById'][0]['stripeAccountId'].present?

      @fundraisers = masjid_data['data']['masjidById'][0]['fundraisers']
      @events = masjid_data['data']['masjidById'][0]['events']
      @prayers = masjid_data['data']['masjidById'][0]['prayers']
      @active_section = 'prayers'

      Rails.logger.debug "Params: #{params}"
      Rails.logger.debug "API Data: #{masjid_data}"
      
    rescue StandardError => e
      Rails.logger.error("Unexpected Error: #{e.message}")
      flash[:notice] = "An unexpected error occurred while fetching fundraisers. Please try again later."
      @fundraisers = [] # Return an empty array as a fallback
    end
  end
end
