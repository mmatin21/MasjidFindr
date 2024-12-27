# app/controllers/masjids_controller.rb
class MasjidsController < ApplicationController
  def index
    # Call the service to fetch masjids
    @masjids_data = GraphQlService.fetch_masjids
    @masjids = @masjids_data['data']['masjids'] # Extract masjids from the response
  end
end
