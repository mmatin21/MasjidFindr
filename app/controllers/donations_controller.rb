class DonationsController < ApplicationController

  def new
    @fundraiser_id = params[:fundraiser_id]
  end

  def create
    donation = GraphQlService.create_donation(
      params[:fundraiser_id],
      params[:amount],
      params[:contact_email],
      params[:contact_first_name],
      params[:contact_last_name],
      params[:contact_phone_number]
    )

    if donation['data']['createDonation']
      redirect_to masjid_fundraiser_path(params[:fundraiser_id]), notice: 'Donation created successfully!'
    else
      redirect_to new_masjid_fundraiser_donation_path(params[:masjid_id], params[:fundraiser_id]), alert: 'Failed to create donation.'
    end
  end
end
