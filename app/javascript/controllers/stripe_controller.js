import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="stripe"
export default class extends Controller {
  static targets = ["form", "cardElement", "errorContainer", "amount", "clientSecret"]

  connect() {
    this.initializeStripe()
    console.log(this.clientSecretTarget.value)
  }

  async initializeStripe() {
    this.stripe = Stripe(stripePublishableKey);

    const clientSecret = this.clientSecretTarget.value;
    const appearance = this.getAppearance();
    this.elements = this.stripe.elements({ appearance, clientSecret });
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

    const { error } = await this.stripe.confirmPayment({
      elements: this.elements, // Use the elements instance
      redirect: "if_required",
    });

    if (error) {
      this.errorContainerTarget.textContent = error.message;
    } else {
      // Payment succeeded, and the user will be redirected to the `return_url`.
      console.log("Payment confirmed!");
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
