import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["sidebar", "overlay"];
  static values = {
    breakpoint: { type: Number, default: 768 }
  };

  connect() {
    // Check screen size on load
    this.checkScreenSize();

    // Listen for window resize events
    window.addEventListener('resize', this.checkScreenSize.bind(this));
  }

  toggle() {
    this.sidebarTarget.classList.toggle('show');
    this.overlayTarget.classList.toggle('d-none');
  }

  close() {
    this.sidebarTarget.classList.remove('show');
    this.overlayTarget.classList.add('d-none');
  }

  checkScreenSize() {
    if (window.innerWidth < this.breakpointValue) {
      this.close();
    }
  }

  disconnect() {
    // Clean up event listener when controller is disconnected
    window.removeEventListener('resize', this.checkScreenSize.bind(this));
  }
}
