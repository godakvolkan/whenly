import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["element", "checkbox"]

  connect() {
    this.update()
  }

  update() {
    if (this.hasCheckboxTarget && this.hasElementTarget) {
      if (this.checkboxTarget.checked) {
        this.elementTarget.classList.remove("hidden")
      } else {
        this.elementTarget.classList.add("hidden")
      }
    }
  }
}
