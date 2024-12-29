import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="stripe"
export default class extends Controller {
  static targets = ["form", "cardElement", "errorContainer"]

  connect() {
    console.log("hello world")
    this.stripe = Stripe('pk_test_51QaoW2Im5wQ2SWSpElNOoW2u560OiFwF1Jxu8NADL2EJbG51c0XCvagpIyj2oREadliTlqMdWyzw1e2pHC96XKtf00M5Js5i5H'); // Your publishable key
    this.elements = this.stripe.elements();
    this.card = this.elements.create("card", {
      style: {
        base: {
          color: "#1f2937", // dark:text-white equivalent
          backgroundColor: "#f9fafb", // bg-gray-50 equivalent
          border: "1px solid #d1d5db", // border-gray-300 equivalent
          borderRadius: "0.375rem", // rounded-lg equivalent
          padding: "0.625rem", // p-2.5 equivalent
          fontSize: "0.875rem", // text-sm equivalent
          fontSmooth: "always",
          fontFamily: "'Inter', sans-serif", // Matches Tailwind's default font
          "::placeholder": {
            color: "#9ca3af", // dark:placeholder:text-gray-400 equivalent
          },
        },
        invalid: {
          color: "#ef4444", // Red for invalid text
        },
        focus: {
          border: "1px solid #3b82f6", // focus:border-primary-500 equivalent
          outline: "none", // Matches focus:ring
        },
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

    console.log("hello world")


    // Adding Turbo Stream support
    
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
