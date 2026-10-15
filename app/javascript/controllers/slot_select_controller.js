import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "startsAt", "selectedSlotTime", "selectedSlotText"]

  select(event) {
    const btn = event.currentTarget
    this.element.querySelectorAll(".slot-btn").forEach(b => b.classList.remove("selected"))
    btn.classList.add("selected")

    const timeStr = btn.dataset.timeFormatted || btn.dataset.displayTime || btn.textContent.trim()

    if (this.hasStartsAtTarget) {
      this.startsAtTarget.value = btn.dataset.startsAt
    }

    if (this.hasSelectedSlotTimeTarget) {
      this.selectedSlotTimeTarget.textContent = timeStr
    }

    if (this.hasSelectedSlotTextTarget) {
      this.selectedSlotTextTarget.textContent = timeStr
    }

    if (this.hasFormTarget) {
      this.formTarget.classList.remove("hidden")
      this.formTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }
  }
}
