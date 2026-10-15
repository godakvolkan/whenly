import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  change(event) {
    const tabName = event.currentTarget.dataset.tab
    this.tabTargets.forEach(t => t.classList.toggle("active", t.dataset.tab === tabName))
    this.panelTargets.forEach(p => p.classList.toggle("hidden", p.dataset.panel !== tabName))
  }
}
