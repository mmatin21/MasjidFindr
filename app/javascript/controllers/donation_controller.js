import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="donation"
export default class extends Controller {
  static targets = ["amount", "total", "checkbox", "minus", "fees"];

  connect() {
    this.updateTotal(); // Initialize the total on page load
  }

  updateTotal() {
    const amount = parseFloat(this.amountTarget.value) || 0; // Default to 0 if empty

    const platformFeePercentage = 0.039; // Example: 4%
    const platformFee = amount > 0 ? (amount * platformFeePercentage) + .30 : 0;

    // Masjid receives amount
    const masjidReceives = amount > 0 ? amount - platformFee : 0

    if (amount >= 0) {
      this.totalTarget.textContent = `$${amount.toFixed(2)}`;
      this.feesTarget.textContent = `$${platformFee.toFixed(2)}`; 
      this.minusTarget.textContent = `$${masjidReceives.toFixed(2)}`; 
    } else {
      this.totalTarget.textContent = "$0.00";
      this.feesTarget.textContent = "$0.00";
      this.minusTarget.textContent = "$0.00";
    }
  }

  toggleFee() {
    // Recalculate the total when the checkbox is toggled
    const feeCheckbox = this.checkboxTarget.checked;
    const amount = parseFloat(this.amountTarget.value)
    const fixedFee = .30
    const percentFee = .039
    
    if(feeCheckbox){
      this.amountTarget.value = this.amountTarget.value > 0 ? ((amount + fixedFee)/(1-percentFee)).toFixed(2) : 0
    }
    this.updateTotal()
  }
}
