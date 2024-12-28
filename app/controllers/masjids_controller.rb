class MasjidsController < ApplicationController
  def index
    # Fetch masjids from the GraphQL API
    @masjids_data = GraphQlService.fetch_masjids
    @masjids = @masjids_data['data']['masjids']
  end

  def show
    # Fetch the fundraisers for the selected masjid
    masjid_id = params[:id]
    @fundraisers_data = GraphQlService.fetch_fundraisers_for_masjid(masjid_id)
    @fundraisers = @fundraisers_data['data']['fundraisers']
    Rails.logger.debug "Masjid: #{params}" 
  end


end
