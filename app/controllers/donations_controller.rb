class DonationsController < ApplicationController
  Stripe.api_key = Rails.application.credentials.stripe[:secret_key] # If you're using credentials

  def new
    @fundraiser_id = params[:fundraiser_id]
    Rails.logger.debug "Fundraiser: #{params}"

  end

  def create
    # Step 1: Parameter validation
    validation_result = validate_donation_params
    return validation_result if validation_result

    # Step 2: Amount processing and validation
    amount_result = process_amount
    return amount_result if amount_result.is_a?(ActionController::Base)
    amount = amount_result

    # Step 3: Masjid validation and retrieval
    masjid_result = fetch_and_validate_masjid
    return masjid_result if masjid_result.is_a?(ActionController::Base)
    masjid = masjid_result

    # Step 4: Process payment
    payment_result = process_stripe_payment(amount, masjid)
    Rails.logger.debug "Payment result: #{payment_result}"
    return payment_result if payment_result.is_a?(ActionController::Base)
    payment_intent = payment_result

    # Step 5: Create donation record
    handle_donation_creation(payment_intent)
  rescue Stripe::StripeError => e
    handle_stripe_error(e)
  rescue StandardError => e
    handle_general_error(e)
  end

  private

  def validate_donation_params
    required_params = [:amount, :masjid_id, :fundraiser_id, :payment_method]
    missing_params = required_params.select { |param| params[param].blank? }

    if missing_params.any?
      redirect_to root_path, 
                 alert: "Missing required parameters: #{missing_params.join(', ')}"
    end
  end

  def process_amount
    amount = (params[:amount].to_f * 100).to_i
    if amount <= 0
      return redirect_to new_masjid_fundraiser_donation_path(params[:masjid_id], params[:fundraiser_id]), 
                        alert: 'Invalid donation amount'
    end
    amount
  end

  def fetch_and_validate_masjid
    masjid_data = GraphQlService.fetch_masjid_by_id(params[:masjid_id])

    unless masjid_data && masjid_data['data'] && masjid_data['data']['masjidById']&.first
      return redirect_to root_path, alert: 'Invalid masjid'
    end

    masjid = masjid_data['data']['masjidById'][0]['stripeAccountId']
    unless masjid.present?
      return redirect_to root_path, alert: 'Masjid not configured for payments'
    end

    masjid
  end

  def process_stripe_payment(amount, masjid)
    Stripe::PaymentIntent.create(
      amount: amount,
      currency: 'usd',
      payment_method: params[:payment_method],
      confirmation_method: 'manual',
      confirm: true,
      transfer_data: {
        destination: masjid
      },
      return_url: masjid_fundraiser_url(params[:masjid_id], params[:fundraiser_id])
    )
  end

  def handle_donation_creation(payment_intent)
    if payment_intent.status == 'succeeded'
      donation = create_donation_record(payment_intent.amount)

      if donation['data']['createDonation']
        redirect_to masjid_fundraiser_path(params[:masjid_id], params[:fundraiser_id]), 
                    notice: 'Donation created successfully!'
      else
        refund_payment(payment_intent.id)
        redirect_to new_masjid_fundraiser_donation_path(params[:masjid_id], params[:fundraiser_id]), 
                    alert: 'Failed to create donation record. Payment has been refunded.'
      end
    else
      redirect_to new_masjid_fundraiser_donation_path(params[:masjid_id], params[:fundraiser_id]), 
                  alert: 'Payment processing failed'
    end
  end

  def create_donation_record(amount_in_cents)
    GraphQlService.create_donation(
      params[:fundraiser_id],
      amount_in_cents / 100.0,
      params[:contact_email]&.strip,
      params[:contact_first_name]&.strip,
      params[:contact_last_name]&.strip,
      params[:contact_phone_number]&.strip
    )
  end

  def refund_payment(payment_intent_id)
    Stripe::Refund.create(payment_intent: payment_intent_id)
  end

  def handle_stripe_error(error)
    render turbo_stream: turbo_stream.replace('turbo-modal',
      partial: 'shared/error_modal',
      locals: { message: error.message }
    )
  end

  def handle_general_error(error)
    Rails.logger.error("Donation creation error: #{error.message}")
    render turbo_stream: turbo_stream.replace('turbo',
      partial: 'shared/error_modal',
      locals: { message: 'An unexpected error occurred' }
    )
  end
end
