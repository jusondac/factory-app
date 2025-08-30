import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop"]

  connect() {
    // Listen for clicks on elements with data-dialog-target
    document.addEventListener("click", this.handleDialogTarget.bind(this))
    // Listen for clicks on elements with data-dialog-close
    document.addEventListener("click", this.handleDialogClose.bind(this))
    // Listen for clicks on elements with data-dialog-backdrop-close
    document.addEventListener("click", this.handleBackdropClose.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleDialogTarget.bind(this))
    document.removeEventListener("click", this.handleDialogClose.bind(this))
    document.removeEventListener("click", this.handleBackdropClose.bind(this))
  }

  handleDialogTarget(event) {
    const target = event.target.closest("[data-dialog-target]")
    if (target) {
      const modalId = target.dataset.dialogTarget
      this.openModal(modalId)
    }
  }

  handleDialogClose(event) {
    const target = event.target.closest("[data-dialog-close]")
    if (target) {
      const modal = target.closest("[data-dialog]")
      if (modal) {
        this.closeModal(modal.dataset.dialog)
      }
    }
  }

  handleBackdropClose(event) {
    const backdrop = event.target.closest("[data-dialog-backdrop]")
    if (backdrop && event.target === backdrop && backdrop.dataset.dialogBackdropClose === "true") {
      this.closeModal(backdrop.dataset.dialogBackdrop)
    }
  }

  openModal(modalId) {
    const backdrop = document.querySelector(`[data-dialog-backdrop="${modalId}"]`)
    if (backdrop) {
      backdrop.classList.remove("pointer-events-none", "opacity-0")
      backdrop.classList.add("pointer-events-auto", "opacity-100")
    }
  }

  closeModal(modalId) {
    const backdrop = document.querySelector(`[data-dialog-backdrop="${modalId}"]`)
    if (backdrop) {
      backdrop.classList.add("pointer-events-none", "opacity-0")
      backdrop.classList.remove("pointer-events-auto", "opacity-100")
    }
  }
}