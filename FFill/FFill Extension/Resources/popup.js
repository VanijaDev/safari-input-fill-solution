// popup.js — FFill toolbar popup
//
// Provides a "Refresh Menu" button that tells the background service worker
// to re-fetch all data from the native app and rebuild the context menu tree.
// Use this after adding or editing items in the FFill macOS app.

const btn = document.getElementById("refreshBtn");
const status = document.getElementById("status");

btn.addEventListener("click", async () => {
    btn.disabled = true;
    status.textContent = "Refreshing…";

    try {
        const response = await browser.runtime.sendMessage({ action: "refresh" });
        if (response?.success) {
            status.textContent = `Updated — ${response.itemCount} item(s)`;
        } else {
            status.textContent = "Failed to refresh.";
        }
    } catch (err) {
        console.error("FFill popup: refresh error", err);
        status.textContent = "Error — check app is running.";
    } finally {
        btn.disabled = false;
    }
});
