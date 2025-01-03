import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="modals"
export default class extends Controller {
  connect() {}
  close(e) {
    // Prevent default action
    e.preventDefault();
    // Remove from parent
    const modal = document.getElementById("turbo-modal");
    modal.innerHTML = "";

    // Remove the src attribute from the modal
    modal.removeAttribute("src");

    // Remove complete attribute
    modal.removeAttribute("complete");
  }
  // hide modal on successful form submission
  // action: "turbo:submit-end->turbo-modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.close(e)
    }
  }
}