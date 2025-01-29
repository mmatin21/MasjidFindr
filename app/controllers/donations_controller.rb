class DonationsController < ApplicationController
  before_action :set_stripe_api_key
  def new
    @fundraiser_id = params[:fundraiser_id]
    Rails.logger.debug "Fundraiser: #{params}"
  end

  def payment_confirmation
    # Use session or params to pass relevant data
    @success = params[:success] == 'true'
    @error_message = params[:error_message]
    @donation = params[:donation] # If needed, retrieve donation details

    return unless @donation.present?

    @amount = @donation['amount'].to_f / 100
    @contact_email = @donation['contact_email']
    @contact_first_name = @donation['contact_first_name']
    @contact_last_name = @donation['contact_last_name']
  end

  def review
    @masjid_id = params[:masjid_id]
    @fundraiser_id = params[:fundraiser_id]
    @amount = params[:amount].to_f
    @contact_email = params[:contact_email]
    @contact_first_name = params[:contact_first_name]
    @contact_last_name = params[:contact_last_name]
    @contact_name = @contact_first_name + ' ' + @contact_last_name
    @amount_in_cents = (@amount * 100).to_i
  end

  def create
    payment_intent_id = params[:payment_intent_id]
    Rails.logger.debug "Payment intent ID: #{payment_intent_id}"

    payment_intent = retrieve_payment_intent(payment_intent_id)
    handle_donation_creation(payment_intent)
  rescue Stripe::StripeError => e
    handle_stripe_error(e)
  rescue StandardError => e
    handle_general_error(e)
  end

  private

  def retrieve_payment_intent(payment_intent_id)
    Stripe::PaymentIntent.retrieve(payment_intent_id)
  end

  def handle_donation_creation(payment_intent)
    Rails.logger.debug "Payment intent: #{payment_intent.metadata.inspect}"
    if payment_intent.status == 'succeeded'
      redirect_to payment_confirmation_masjid_fundraiser_donations_path(
        success: true,
        donation: payment_intent.metadata.to_h
      )
    else
      redirect_to payment_confirmation_masjid_fundraiser_donations_path(error_message: 'Payment failed')
    end
  end

  def handle_stripe_error(error)
    redirect_to payment_confirmation_masjid_fundraiser_donations_path(error: error.message)
  end

  def handle_general_error(error)
    redirect_to payment_confirmation_masjid_fundraiser_donations_path(error: error.message)
  end

  def set_stripe_api_key
    Stripe.api_key = Rails.application.credentials.stripe[:secret_key] # If you're using credentials
  end
end
