import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["liveIndicator"]

  connect() {
    this.handler = this.handleBookingUpdate.bind(this)
    window.addEventListener("booking:updated", this.handler)
  }

  disconnect() {
    window.removeEventListener("booking:updated", this.handler)
  }

  handleBookingUpdate(event) {
    const indicator = this.liveIndicatorTarget
    indicator.classList.add("pulse")
    setTimeout(() => indicator.classList.remove("pulse"), 2000)

    // Reload page to reflect new data
    window.Turbo.visit(window.location.href, { action: "replace" })
  }
}
