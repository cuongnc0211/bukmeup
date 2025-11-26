import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["breakTemplate"]

  toggleDay(event) {
    const checkbox = event.target
    const day = checkbox.dataset.day
    const openInput = this.element.querySelector(`[data-operating-hours-target="${day}Open"]`)
    const closeInput = this.element.querySelector(`[data-operating-hours-target="${day}Close"]`)
    const breaksContainer = this.element.querySelector(`[data-operating-hours-target="${day}Breaks"]`)
    const addBreakButton = breaksContainer.querySelector('button[data-action*="addBreak"]')

    // Disable/enable main operating hours
    openInput.disabled = checkbox.checked
    closeInput.disabled = checkbox.checked

    // Disable/enable all break inputs for this day
    const breakInputs = breaksContainer.querySelectorAll('input[type="time"]')
    breakInputs.forEach(input => input.disabled = checkbox.checked)

    // Disable/enable "Add Break" button
    addBreakButton.disabled = checkbox.checked
  }

  addBreak(event) {
    const button = event.target
    const day = button.dataset.day
    const breaksContainer = this.element.querySelector(`[data-operating-hours-target="${day}Breaks"]`)
    const breaksList = breaksContainer.querySelector('.space-y-2')

    // Clone the template
    const template = this.breakTemplateTarget
    const clone = template.content.cloneNode(true)

    // Replace DAY_PLACEHOLDER with actual day name
    const inputs = clone.querySelectorAll('input')
    inputs.forEach(input => {
      input.name = input.name.replace('DAY_PLACEHOLDER', day)
    })

    // Add to the breaks list
    breaksList.appendChild(clone)
  }

  removeBreak(event) {
    const button = event.target
    const breakRow = button.closest('[data-operating-hours-target="breakRow"]')
    breakRow.remove()
  }
}
