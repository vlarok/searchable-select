// Triggers a change event when the hidden input is changed programmatically
export let SearchableSelect = {
    updated(_e) {
        this.el.dispatchEvent(new Event('change', { 'bubbles': true }))
    }
}
