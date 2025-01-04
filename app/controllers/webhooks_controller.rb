class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_key) # Use credentials

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: 400 and return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: 400 and return
    end

    case event['type']
    when 'payment_intent.succeeded'
      handle_successful_payment(event['data']['object'])
    when 'charge.failed'
      handle_failed_charge(event['data']['object'])
    else
      Rails.logger.info("Unhandled event type: #{event['type']}")
    end

    render json: { message: 'success' }, status: 200
  end

  private

  def handle_successful_payment(payment_intent)
    Rails.logger.info("Payment succeeded: #{payment_intent['id']}")
  end

  def handle_failed_charge(charge)
    Rails.logger.info("Charge failed: #{charge['id']}")
  end
end
