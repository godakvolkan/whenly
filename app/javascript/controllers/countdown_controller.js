import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { deadline: String }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  tick() {
    const now = new Date()
    const deadline = new Date(this.deadlineValue)
    const diff = deadline - now

    if (diff <= 0) {
      this.element.textContent = "Süresi doldu"
      this.element.classList.add("text-danger")
      clearInterval(this.timer)
      return
    }

    const hours = Math.floor(diff / 3600000)
    const minutes = Math.floor((diff % 3600000) / 60000)
    const seconds = Math.floor((diff % 60000) / 1000)
    this.element.textContent = `${hours}s ${minutes}dk ${seconds}sn`
  }
}
