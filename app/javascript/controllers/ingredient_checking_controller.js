import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "status", "badge", "progressText", "progressBar"]
  static values = {
    prepareId: Number,
    updateUrl: String
  }

  connect() {
    console.log("Ingredient checking controller connected")
  }

  async toggleCheck(event) {
    // Prevent default form submission
    event.preventDefault()

    const clickedElement = event.currentTarget
    const checkbox = clickedElement.querySelector('input[type="checkbox"]')
    const ingredientId = checkbox.dataset.ingredientId
    const ingredientItem = clickedElement.closest('.ingredient-item')

    console.log('Toggle check clicked for ingredient:', ingredientId)

    // Show loading state
    this.setLoadingState(ingredientItem, true)

    try {
      const response = await fetch(this.updateUrlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken(),
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          prepare_ingredient_id: ingredientId
        })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      console.log('Response data:', data)

      if (data.success) {
        this.updateIngredientUI(ingredientItem, data.ingredient)
        this.updateProgress(data.progress)

        // Show completion message if all ingredients are checked
        if (data.all_completed) {
          this.showCompletionMessage()
        }
      } else {
        this.showError(data.message || 'Failed to update ingredient status')
      }

    } catch (error) {
      console.error('Error updating ingredient:', error)
      this.showError('An error occurred while updating the ingredient status')
    } finally {
      this.setLoadingState(ingredientItem, false)
    }
  }

  updateIngredientUI(ingredientItem, ingredientData) {
    const checkbox = ingredientItem.querySelector('input[type="checkbox"]')
    const statusBadge = ingredientItem.querySelector('.status-badge')
    const customCheckbox = ingredientItem.querySelector('.custom-checkbox')
    const helpText = ingredientItem.querySelector('.help-text')
    const numberBadge = ingredientItem.querySelector('.number-badge')

    // Update checkbox state
    checkbox.checked = ingredientData.checked

    // Update visual checkbox
    if (ingredientData.checked) {
      customCheckbox.classList.remove('border-gray-300', 'group-hover:border-gray-400')
      customCheckbox.classList.add('bg-green-500', 'border-green-500')
      customCheckbox.innerHTML = `
        <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
      `
    } else {
      customCheckbox.classList.remove('bg-green-500', 'border-green-500')
      customCheckbox.classList.add('border-gray-300', 'group-hover:border-gray-400')
      customCheckbox.innerHTML = ''
    }

    // Update status badge
    if (statusBadge) {
      if (ingredientData.checked) {
        statusBadge.className = 'ml-3 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700 status-badge'
        statusBadge.textContent = '✓ Checked'
      } else {
        statusBadge.className = 'ml-3 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600 status-badge'
        statusBadge.textContent = 'Pending'
      }
    }

    // Update help text
    if (helpText) {
      helpText.textContent = `Click to ${ingredientData.checked ? 'uncheck' : 'check'} this ingredient`
    }

    // Update number badge color
    if (numberBadge) {
      if (ingredientData.checked) {
        numberBadge.classList.remove('bg-blue-100', 'text-blue-600')
        numberBadge.classList.add('bg-green-100', 'text-green-700')
      } else {
        numberBadge.classList.remove('bg-green-100', 'text-green-700')
        numberBadge.classList.add('bg-blue-100', 'text-blue-600')
      }
    }

    // Update container styling
    if (ingredientData.checked) {
      ingredientItem.classList.remove('border-gray-200')
      ingredientItem.classList.add('bg-green-50', 'border-green-200', 'shadow-sm')
    } else {
      ingredientItem.classList.remove('bg-green-50', 'border-green-200', 'shadow-sm')
      ingredientItem.classList.add('border-gray-200')
    }
  }

  updateProgress(progressData) {
    // Update progress text in header
    const progressTextElements = document.querySelectorAll('.progress-text')
    progressTextElements.forEach(element => {
      element.innerHTML = `<span class="font-medium text-green-600">${progressData.checked_count}</span> of <span class="font-medium">${progressData.total_count}</span> checked`
    })

    // Update remaining count
    const remainingElements = document.querySelectorAll('.remaining-count')
    remainingElements.forEach(element => {
      if (progressData.remaining_count === 0) {
        element.innerHTML = `
          <div class="flex items-center text-green-600">
            <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span class="text-sm font-medium">Complete!</span>
          </div>
        `
      } else {
        element.innerHTML = `
          <span class="text-sm text-yellow-600 font-medium">
            ${progressData.remaining_count} remaining
          </span>
        `
      }
    })
  }

  showCompletionMessage() {
    // Could add a toast notification or modal here
    console.log("All ingredients checked!")
  }

  setLoadingState(ingredientItem, isLoading) {
    const checkbox = ingredientItem.querySelector('input[type="checkbox"]')
    const customCheckbox = ingredientItem.querySelector('.custom-checkbox')

    if (isLoading) {
      checkbox.disabled = true
      customCheckbox.classList.add('opacity-50')
      ingredientItem.classList.add('pointer-events-none')
    } else {
      checkbox.disabled = false
      customCheckbox.classList.remove('opacity-50')
      ingredientItem.classList.remove('pointer-events-none')
    }
  }

  showError(message) {
    // Simple error display - could be enhanced with toast notifications
    alert(message)
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }
}
