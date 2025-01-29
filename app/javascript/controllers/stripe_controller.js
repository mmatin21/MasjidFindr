import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="stripe"
export default class extends Controller {
  static targets = ["form", "cardElement", "errorContainer", "amount", "masjidId", "fundraiserId", "contactEmail", "contactLastName", "contactFirstName"]

  connect() {
    this.initializeStripe()
  }

  async initializeStripe() {
    const masjidId = this.masjidIdTarget.value;
    const fundraiserId = this.fundraiserIdTarget.value;
    const amount = this.amountTarget.value;
    const email = this.contactEmailTarget.value;
    const firstName = this.contactFirstNameTarget.value;
    const lastName = this.contactLastNameTarget.value;

    
    this.stripe = Stripe(stripePublishableKey);
    const response = await fetch(`/payment_intents/get_payment_intent?masjid_id=${masjidId}&fundraiser_id=${fundraiserId}&amount=${amount}&contact_email=${email}&contact_first_name=${firstName}&contact_last_name=${lastName}`)
    const { client_secret } = await response.json()
    const appearance = this.getAppearance();
    this.elements = this.stripe.elements({ appearance, clientSecret: client_secret });
    const options = {
      layout: {
        type: 'tabs',
        defaultCollapsed: true,
      }
    };
  

    this.paymentElement = this.elements.create("payment", options);
    this.paymentElement.mount(this.cardElementTarget);

    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", this.updateTheme.bind(this));
  }
  // Handle form submission
  async handleSubmit(event) {
    event.preventDefault();

    const { paymentIntent, error } = await this.stripe.confirmPayment({
      elements: this.elements, // Use the elements instance
      redirect: "if_required",
    });

    if (error) {
      this.errorContainerTarget.textContent = error.message;
    } else {
      // Payment succeeded, and the user will be redirected to the `return_url`.
      console.log("Payment confirmed!");
    }

    let existingInput = this.formTarget.querySelector("input[name='payment_intent_id']");
    if (existingInput) {
      existingInput.value = paymentIntent.id;
    } 
    else {
      const hiddenInput = document.createElement("input");
      hiddenInput.type = "hidden";
      hiddenInput.name = "payment_intent_id";
      hiddenInput.value = paymentIntent.id;
      this.formTarget.appendChild(hiddenInput);
    }

    this.formTarget.submit();
  }

  getAppearance() {
    const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)").matches;
    return { theme: prefersDarkScheme ? "night" : "stripe" };
  }

  updateTheme(event) {
    const newAppearance = { theme: event.matches ? "night" : "stripe" };
    // Remount the Payment Element with the updated theme
    this.paymentElement.update({ appearance: newAppearance });
  }
}
