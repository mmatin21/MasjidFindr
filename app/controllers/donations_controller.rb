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

    payment_intent = get_payment_intent
    @client_secret = payment_intent.client_secret
    session[:payment_intent_id] = payment_intent.id
  end

  def create
    payment_intent_id = session[:payment_intent_id]
    session.delete(:payment_intent_id)
    Rails.logger.debug "Payment intent ID: #{payment_intent_id}"

    payment_intent = retrieve_payment_intent(payment_intent_id)
    handle_donation_creation(payment_intent)
  rescue Stripe::StripeError => e
    handle_stripe_error(e)
  rescue StandardError => e
    handle_general_error(e)
  end

  private

  def get_payment_intent
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

    fee_result = process_fee
    return fee_result if fee_result.is_a?(ActionController::Base)

    fee = fee_result

    payment_result = create_stripe_payment_intent(amount, masjid, fee)
    return payment_result if payment_result.is_a?(ActionController::Base)

    payment_result
  end

  def validate_donation_params
    required_params = %i[amount masjid_id fundraiser_id]

    missing_params = required_params.select { |param| params[param].blank? }

    nil unless missing_params.any?
  end

  def process_amount
    amount = (params[:amount].to_f * 100).to_i
    if amount <= 0
      return redirect_to new_masjid_fundraiser_donation_path(params[:masjid_id], params[:fundraiser_id]),
                         alert: 'Invalid donation amount'
    end

    amount
  end

  def process_fee
    amount_in_cents = (params[:amount].to_f * 100).to_i
    ((amount_in_cents * 0.039) + 30).round
  end

  def fetch_and_validate_masjid
    masjid_data = GraphQlService.fetch_masjid_by_id(params[:masjid_id])

    unless masjid_data && masjid_data['data'] && masjid_data['data']['masjidById']&.first
      return redirect_to root_path, alert: 'Invalid masjid'
    end

    masjid = masjid_data['data']['masjidById'][0]['stripeAccountId']
    Rails.logger.debug "Masjid: #{masjid}"
    return redirect_to root_path, alert: 'Masjid not configured for payments' unless masjid.present?

    masjid
  end

  def create_stripe_payment_intent(amount, masjid, fee)
    Stripe::PaymentIntent.create(
      amount: amount,
      currency: 'usd',
      payment_method_types: %w[card us_bank_account],
      metadata: {
        amount: amount,
        masjid_id: params[:masjid_id],
        fundraiser_id: params[:fundraiser_id],
        contact_email: params[:contact_email],
        contact_first_name: params[:contact_first_name],
        contact_last_name: params[:contact_last_name],
        fee: fee
      },
      application_fee_amount: fee,
      transfer_data: {
        destination: masjid
      }
    )
  end

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

  def refund_payment(payment_intent_id)
    Stripe::Refund.create(payment_intent: payment_intent_id)
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
