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
    this.elements = this.stripe.elements({ clientSecret });
    const appearance = { theme: "stripe" };

    this.paymentElement = this.elements.create("payment", { appearance });
    this.paymentElement.mount(this.cardElementTarget);
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
}
