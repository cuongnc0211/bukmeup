import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    // Optional: Close sidebar on resize if screen becomes large
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
  }

  disconnect() {
    window.removeEventListener('resize', this.resizeHandler)
  }

  toggle() {
    this.sidebarTarget.classList.toggle("-translate-x-full")
    this.overlayTarget.classList.toggle("hidden")
    document.body.classList.toggle("overflow-hidden")
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  handleResize() {
    if (window.innerWidth >= 768) { // md breakpoint
      this.close()
    }
  }
}
