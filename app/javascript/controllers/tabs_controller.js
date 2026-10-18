import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  switch(event) {
    this.activate(event.currentTarget)
  }

  change(event) {
    this.activate(event.currentTarget)
  }

  activate(clickedTab) {
    const targetName = clickedTab.dataset.tabTarget || clickedTab.dataset.tab

    this.tabTargets.forEach(t => {
      const name = t.dataset.tabTarget || t.dataset.tab
      t.classList.toggle("active", name === targetName)
    })

    this.panelTargets.forEach(p => {
      const pName = p.dataset.panelName || p.dataset.panel
      p.classList.toggle("hidden", pName !== targetName)
    })
  }
}
