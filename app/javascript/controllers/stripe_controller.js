import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="stripe"
export default class extends Controller {
  static targets = ["form", "cardElement", "errorContainer", "expressCheckoutButton", "amount"]

  connect() {
    console.log("hello world")
    this.stripe = Stripe(stripePublishableKey); // Your publishable key
    this.elements = this.stripe.elements();
    this.card = this.elements.create("card", {
      style: {
        base: {
          color: "#9ca3af", // dark:text-white equivalent
          fontFamily: "'Inter', sans-serif", // Matches Tailwind's default font
          "::placeholder": {
            color: "#9ca3af", // dark:placeholder:text-gray-400 equivalent
          },
        },
        invalid: {
          color: "#ef4444", // Red for invalid text
        }
      },
    });
    this.card.mount(this.cardElementTarget);
    
    this.card.on("change", (event) => {
      const displayError = document.getElementById("card-errors");
      if (event.error) {
        displayError.textContent = event.error.message;
      } else {
        displayError.textContent = "";
      }
    });

    this.showExpressCheckout()

    // Adding Turbo Stream support

  }

  showExpressCheckout() {
    const amountInCents = parseInt(this.amountTarget.value, 10);

    if (amountInCents > 0 && !isNaN(amountInCents)) {
      // Unmount existing element if it exists
      if (this.expressCheckoutElement) {
        this.expressCheckoutElement.unmount();
      }
      
      const elements = this.stripe.elements({
        mode: 'payment',
        amount: amountInCents,
        currency: 'usd'
      });
      
      this.expressCheckoutElement = elements.create('expressCheckout');
      this.expressCheckoutElement.mount(this.expressCheckoutButtonTarget);
    } else {
      if (this.expressCheckoutElement) {
        this.expressCheckoutElement.unmount();
      }
    }
  }



  // Handle form submission
  async handleSubmit(event) {
    event.preventDefault(); // Prevent the default form submission

    // Create a payment method
    const { error, paymentMethod } = await this.stripe.createPaymentMethod('card', this.card);

    if (error) {
      // Display error in the form
      this.errorContainerTarget.textContent = error.message;
    } else {
      // Add the payment method ID to the form as a hidden input
      const paymentMethodInput = document.createElement('input');
      paymentMethodInput.type = 'hidden';
      paymentMethodInput.name = 'payment_method';
      paymentMethodInput.value = paymentMethod.id;
      this.formTarget.appendChild(paymentMethodInput);

      // Submit the form after attaching the payment method
      console.log('Submitting form with payment method:', paymentMethod.id)
      this.formTarget.submit();
    }
  }
}
