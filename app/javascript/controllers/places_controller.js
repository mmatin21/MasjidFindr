import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["autocomplete"];

  connect() {
    if (this.hasAutocompleteTarget) {
      this.autocomplete = new google.maps.places.Autocomplete(
        this.autocompleteTarget,
        { types: ["geocode"] }
      );
    } else {
      console.error("Autocomplete target not found or is not an input element.");
    }
  }
}
