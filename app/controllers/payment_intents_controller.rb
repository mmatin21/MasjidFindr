class PaymentIntentsController < ApplicationController
  def get_payment_intent
    Rails.logger.debug "Payment Intent Controller: #{params}"

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

    render json: { client_secret: payment_result.client_secret }
  end

  private

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
end
