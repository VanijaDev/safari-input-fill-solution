// content.js — FFill Safari Web Extension
//
// Responsibilities:
//   1. Track which element the user right-clicked (for the context menu).
//   2. Listen for { action: "fillField", value } messages from background.js.
//   3. Fill the target element using the native setter trick so React/Vue/Angular
//      frameworks detect the change and update their state.

// The most recently right-clicked element. Falls back to document.activeElement.
let lastRightClickedElement = null;

document.addEventListener("contextmenu", (event) => {
    lastRightClickedElement = event.target;
});

// ── Field filling ─────────────────────────────────────────────────────────────

/**
 * Sets the value of a form field in a way that frameworks pick up.
 *
 * Plain assignment (`element.value = v`) bypasses the native setter, so
 * frameworks like React that track the setter via Object.defineProperty never
 * see the change. Calling the native setter directly triggers the internal
 * setter logic, and dispatching synthetic input/change events causes the
 * framework to sync its virtual DOM.
 *
 * @param {Element} element  The target form element.
 * @param {string}  value    The value to write.
 */
function fillField(element, value) {
    if (element instanceof HTMLInputElement) {
        const nativeSetter = Object.getOwnPropertyDescriptor(
            HTMLInputElement.prototype, "value"
        )?.set;
        if (nativeSetter) {
            nativeSetter.call(element, value);
        } else {
            element.value = value;
        }
    } else if (element instanceof HTMLTextAreaElement) {
        const nativeSetter = Object.getOwnPropertyDescriptor(
            HTMLTextAreaElement.prototype, "value"
        )?.set;
        if (nativeSetter) {
            nativeSetter.call(element, value);
        } else {
            element.value = value;
        }
    } else if (element.isContentEditable) {
        // contentEditable elements (e.g. rich-text editors) use textContent / innerHTML
        element.textContent = value;
    } else {
        // Generic fallback
        element.value = value;
    }

    // Dispatch events so frameworks (React, Vue, Angular) sync their state
    element.dispatchEvent(new Event("input", { bubbles: true }));
    element.dispatchEvent(new Event("change", { bubbles: true }));
}

// ── Message listener ──────────────────────────────────────────────────────────

browser.runtime.onMessage.addListener((message) => {
    if (message?.action !== "fillField") return;

    // Prefer the element that received the right-click; fall back to focused element
    const target = lastRightClickedElement ?? document.activeElement;
    if (!target || target === document.body) return;

    fillField(target, String(message.value ?? ""));
});
