class DonationsController < ApplicationController
  Stripe.api_key = Rails.application.credentials.stripe[:secret_key] # If you're using credentials

  def new
    @fundraiser_id = params[:fundraiser_id]
    Rails.logger.debug "Fundraiser: #{params}"
  end

  def payment_confirmation
    # Use session or params to pass relevant data
    @success = params[:success] == "true"
    @error_message = params[:error_message]
    Rails.logger.debug "Donation: #{params[:donation]}"
    @donation = params[:donation] # If needed, retrieve donation details
    if @donation.present?
      @amount = @donation['amount'].to_f.round(2)
      @amount = (@amount + 0.30) / (1 - 0.039)
      @contact = @donation['contact']
    end
  end

  def review
    @masjid_id = params[:masjid_id]
    @fundraiser_id = params[:fundraiser_id]
    @amount = params[:amount].to_f
    Rails.logger.debug "Amount: #{@amount}"
    @contact_email = params[:contact_email]
    @contact_name = params[:contact_first_name] + " " + params[:contact_last_name]
    @amount_in_cents = (@amount * 100).to_i
    @installments = params[:installments].present? ? params[:installments].to_i : nil
    if @installments.present?
      @installment_amount = @amount / @installments
    end
    Rails.logger.debug "Amount in cents: #{@amount_in_cents}"

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "donation_form",
          partial: "donations/review"
        )
      end
    end
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
    if params[:installments].present?
      installment_duration = params[:installments].to_i
      customer = create_stripe_customer(params[:contact_email])

      # Create a subscription instead of multiple payment intents
      subscription_result = create_stripe_subscription(masjid, customer, amount, installment_duration)
      return subscription_result if subscription_result.is_a?(ActionController::Base)

      subscription = subscription_result
    else
      payment_result = process_stripe_payment(amount, masjid)
      return payment_result if payment_result.is_a?(ActionController::Base)

      payment_intent = payment_result
      
      # Step 5: Create donation record
      handle_donation_creation(payment_intent)
    end

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
    # Calculate platform fee (1%) - amount is in cents
    platform_fee = (amount * 0.01).round
    payment = Stripe::PaymentIntent.create(
      amount: amount,
      currency: 'usd',
      payment_method: params[:payment_method],
      confirmation_method: 'manual',
      confirm: true,
      application_fee_amount: platform_fee,
      transfer_data: {
        destination: masjid,
      },
      return_url: masjid_fundraiser_url(params[:masjid_id], params[:fundraiser_id])
    )
  end

  def create_stripe_subscription(masjid, customer, amount, installment_months)
    # Calculate monthly amount and platform fee
    monthly_amount = (amount / installment_months).round
    platform_fee = 1.0

    # Create a product for this donation plan
    # Create product on masjid's Stripe account
    product = Stripe::Product.create({
      name: "Monthly Donation Plan",
      type: 'service'
    })

    # Create price on masjid's Stripe account
    price = Stripe::Price.create({
      product: product.id,
      unit_amount: monthly_amount,
      currency: 'usd',
      recurring: {
        interval: 'month',
        interval_count: 1
      }
    })

    # Attach payment method to customer on masjid's account
    Stripe::PaymentMethod.attach(params[:payment_method], { 
      customer: customer.id 
    })

    # Set default payment method on masjid's account
    Stripe::Customer.update(customer.id, {
      invoice_settings: {
        default_payment_method: params[:payment_method],
      }
    })

    # Create subscription on masjid's account
    Stripe::Subscription.create({
      customer: customer.id,
      items: [{ price: price.id }],
      metadata: {
        total_amount: amount,
        total_installments: installment_months,
        masjid_id: params[:masjid_id],
        fundraiser_id: params[:fundraiser_id]
      },
      application_fee_percent: platform_fee,
      transfer_data: {
        destination: masjid,
      },
      cancel_at: (Time.now + (installment_months * 30 * 24 * 60 * 60)).to_i
    })

    redirect_to masjid_fundraiser_url(params[:masjid_id], params[:fundraiser_id]), 
                    alert: 'Failed to create donation record. Payment has been refunded.'
  end

  def handle_donation_creation(payment_intent)

    if payment_intent.status == 'succeeded'
      donation = create_donation_record(payment_intent.amount)

      if donation['data']['createDonation']
        redirect_to payment_confirmation_masjid_fundraiser_donations_path(success: true, donation: donation['data']['createDonation']['donation']),
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
    amount = amount_in_cents / 100.0
    fixed_fee = 0.30
    percent_fee = 0.039
    amount_after_fee = amount - (amount * percent_fee) - fixed_fee
    GraphQlService.create_donation(
      params[:fundraiser_id],
      amount_after_fee,
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
    redirect_to payment_confirmation_masjid_fundraiser_donations_path(error: error.message)
  end

  def handle_general_error(error)
    redirect_to payment_confirmation_masjid_fundraiser_donations_path(error: error.message)
  end

  def create_stripe_customer(email)
    Stripe::Customer.create({
      email: email
    })
  end
end
