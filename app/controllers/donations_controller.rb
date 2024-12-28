class DonationsController < ApplicationController
  Stripe.api_key = Rails.application.credentials.stripe[:secret_key] # If you're using credentials


  def new
    @fundraiser_id = params[:fundraiser_id]
  end

  def create
    amount = params[:amount].to_i * 100

    masjid_data = GraphQlService.fetch_masjid_by_id(params[:masjid_id])
    masjid = masjid_data['data']['masjidById'][0]['stripeAccountId']


    begin
      payment_intent = Stripe::PaymentIntent.create(
        amount: amount,
        currency: 'usd',
        payment_method: params[:payment_method],
        confirmation_method: 'manual',
        confirm: true,
        transfer_data: {
          destination: masjid# Send the funds to the masjid's Stripe account
        },
        return_url: "http://localhost:3000/masjids"
      )
      Rails.logger.debug "payment intent status: #{payment_intent.status}" 

      if payment_intent.status == 'succeeded'
      
        donation = GraphQlService.create_donation(
          params[:fundraiser_id],
          params[:amount],
          params[:contact_email],
          params[:contact_first_name],
          params[:contact_last_name],
          params[:contact_phone_number]
        )
        Rails.logger.debug "Fundraiser: #{params}" 

        if donation['data']['createDonation']
          redirect_to masjid_fundraiser_path(params[:masjid_id], params[:fundraiser_id]), notice: 'Donation created successfully!'
        else
          redirect_to new_masjid_fundraiser_donation_path(params[:masjid_id], params[:fundraiser_id]), alert: 'Failed to create donation.'
        end
      end
    rescue Stripe::StripeError => e
      redirect_to new_masjid_fundraiser_donation_path(params[:masjid_id], params[:fundraiser_id]), alert: e.message
    end
  end 
end
