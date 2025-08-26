import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="machine-checkings"
export default class extends Controller {
  static targets = ["container", "template"]
  static values = { index: Number }

  connect() {
    this.indexValue = this.containerTarget.children.length
  }

  add(event) {
    event.preventDefault()
    
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.indexValue)
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    this.indexValue++
  }

  remove(event) {
    event.preventDefault()
    
    const item = event.target.closest(".machine-checking-item")
    const destroyInput = item.querySelector("input[name*='_destroy']")
    
    if (destroyInput) {
      // For existing records, mark for destruction
      destroyInput.value = "1"
      item.style.display = "none"
    } else {
      // For new records, just remove from DOM
      item.remove()
    }
  }

  updateCheckingType(event) {
    const checkingItem = event.target.closest(".machine-checking-item")
    const valueInput = checkingItem.querySelector(".checking-value-input")
    const valueHelp = checkingItem.querySelector(".checking-value-help")
    
    if (event.target.value === "text") {
      valueInput.placeholder = "Leave empty for text input"
      valueHelp.textContent = "Leave empty for free text input"
    } else {
      valueInput.placeholder = "Good, Fair, Poor (comma separated)"
      valueHelp.textContent = "For options: enter comma-separated values"
    }
  }
}
