import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "list", "nameInput", "addButton", "cancelButton", "submitButton"]
  static values = { productId: Number }

  connect() {
    this.formVisible = false
  }

  showForm() {
    this.formTarget.classList.remove("hidden")
    this.addButtonTarget.classList.add("hidden")
    this.nameInputTarget.focus()
    this.formVisible = true
  }

  hideForm() {
    this.formTarget.classList.add("hidden")
    this.addButtonTarget.classList.remove("hidden")
    this.nameInputTarget.value = ""
    this.formVisible = false
  }

  cancel(event) {
    event.preventDefault()
    this.hideForm()
  }

  async submit(event) {
    event.preventDefault()

    const name = this.nameInputTarget.value.trim()
    if (!name) {
      this.showError("Please enter an ingredient name")
      return
    }

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Adding..."

    try {
      const response = await fetch(`/products/${this.productIdValue}/add_ingredient`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          ingredient: { name: name }
        })
      })

      const data = await response.json()

      if (data.success) {
        this.addIngredientToList(data.id, data.name)
        this.hideForm()
        this.updateIngredientCount()
      } else {
        this.showError(data.errors ? data.errors.join(", ") : "Failed to add ingredient")
      }
    } catch (error) {
      this.showError("An error occurred. Please try again.")
    } finally {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = "Add"
    }
  }

  async removeIngredient(event) {
    event.preventDefault()

    const ingredientCard = event.target.closest('.ingredient-card')
    const ingredientId = ingredientCard.dataset.ingredientId

    if (!confirm("Are you sure you want to remove this ingredient?")) {
      return
    }

    try {
      const response = await fetch(`/products/${this.productIdValue}/remove_ingredient?ingredient_id=${ingredientId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })

      const data = await response.json()

      if (data.success) {
        ingredientCard.remove()
        this.updateIngredientCount()
      } else {
        this.showError("Failed to remove ingredient")
      }
    } catch (error) {
      this.showError("An error occurred. Please try again.")
    }
  }

  addIngredientToList(id, name) {
    const ingredientCard = this.createIngredientCard(id, name)

    // If this is the first ingredient, remove the empty state
    const emptyState = this.listTarget.querySelector('.empty-state')
    if (emptyState) {
      emptyState.remove()
    }

    // Find the grid container or create one
    let gridContainer = this.listTarget.querySelector('.ingredients-grid')
    if (!gridContainer) {
      gridContainer = document.createElement('div')
      gridContainer.className = 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 ingredients-grid'
      this.listTarget.appendChild(gridContainer)
    }

    gridContainer.appendChild(ingredientCard)
  }

  createIngredientCard(id, name) {
    const cardHTML = `
      <div class="bg-white/40 backdrop-blur-sm rounded-xl p-4 border border-white/20 group hover:bg-white/60 transition-colors duration-200 ingredient-card" data-ingredient-id="${id}">
        <div class="flex items-center justify-between">
          <div class="flex items-center flex-1 min-w-0">
            <div class="w-8 h-8 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg flex items-center justify-center mr-3">
              <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
              </svg>
            </div>
            <span class="font-medium text-gray-900 truncate">${name}</span>
          </div>
          <div class="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
            <button data-action="click->ingredient-form#removeIngredient" class="inline-flex items-center p-1 text-red-600 hover:text-red-800 rounded">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    `

    const div = document.createElement('div')
    div.innerHTML = cardHTML
    return div.firstElementChild
  }

  updateIngredientCount() {
    const ingredientCards = this.listTarget.querySelectorAll('.ingredient-card')
    const countElement = document.querySelector('.ingredient-count')
    if (countElement) {
      const count = ingredientCards.length
      countElement.textContent = count

      // Update the description text
      const descElement = document.querySelector('.ingredient-description')
      if (descElement) {
        descElement.textContent = `${count} ${count === 1 ? 'ingredient' : 'ingredients'} defined`
      }

      // Update the stats card
      const statsCard = document.querySelector('.ingredients-stats')
      if (statsCard) {
        statsCard.textContent = count
      }
    }
  }

  showError(message) {
    // Create or update error message
    let errorDiv = this.formTarget.querySelector('.error-message')
    if (!errorDiv) {
      errorDiv = document.createElement('div')
      errorDiv.className = 'error-message text-red-600 text-sm mt-2'
      this.formTarget.appendChild(errorDiv)
    }
    errorDiv.textContent = message

    // Remove error after 5 seconds
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }
}
