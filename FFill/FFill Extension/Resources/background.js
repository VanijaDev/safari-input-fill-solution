// background.js — FFill Safari Web Extension
//
// Responsibilities:
//   1. On install/startup, fetch FormItems + Folders from the native app via native messaging.
//   2. Build a "FFill" context menu tree:
//        FFill (root)
//          ├── ungrouped items (no folder)
//          ├── ── separator (if both ungrouped items and folders exist)
//          └── folder submenus → their items
//   3. On context menu item click, send { action: "fillField", value } to the active tab's content.js.

const APP_BUNDLE_ID = "vanija-dev.FFill";

// In-memory cache of the last-fetched data
let formData = { items: [], folders: [] };

// ── Native messaging ──────────────────────────────────────────────────────────

/**
 * Ask the native Swift app for all FormItems and Folders.
 * On success, caches the data and rebuilds the context menu tree.
 */
async function fetchFormData() {
    try {
        const response = await browser.runtime.sendNativeMessage(
            APP_BUNDLE_ID,
            { action: "getFormData" }
        );

        if (response?.success && response.data) {
            formData = response.data;
            await rebuildMenus();
        } else {
            console.error("FFill: native app returned failure", response?.error ?? "(no error detail)");
        }
    } catch (err) {
        console.error("FFill: sendNativeMessage error", err);
    }
}

// ── Context menu management ───────────────────────────────────────────────────

/**
 * Remove all existing FFill menus, then rebuild from current formData.
 * Returns a Promise so callers can await completion.
 */
function rebuildMenus() {
    return new Promise((resolve) => {
        browser.contextMenus.removeAll(() => {
            buildMenus();
            resolve();
        });
    });
}

/**
 * Construct the full context menu tree from formData.
 * Exported for unit testing (ESM).
 */
function buildMenus() {
    const { items, folders } = formData;

    // Root entry — always created, even when empty, so users see "FFill" in the menu
    browser.contextMenus.create({
        id: "ffill-root",
        title: "FFill",
        contexts: ["editable"]
    });

    // Items that belong to no folder
    const ungrouped = items.filter(item => !item.folderId);
    for (const item of ungrouped) {
        browser.contextMenus.create({
            id: `ffill-item-${item.id}`,
            parentId: "ffill-root",
            title: item.key,
            contexts: ["editable"]
        });
    }

    // Separator between ungrouped items and folders (only when both exist)
    if (ungrouped.length > 0 && folders.length > 0) {
        browser.contextMenus.create({
            id: "ffill-sep",
            parentId: "ffill-root",
            type: "separator",
            contexts: ["editable"]
        });
    }

    // Folder submenus, each containing their items in sortOrder
    for (const folder of folders) {
        browser.contextMenus.create({
            id: `ffill-folder-${folder.id}`,
            parentId: "ffill-root",
            title: folder.name,
            contexts: ["editable"]
        });

        for (const itemId of folder.itemIds) {
            const item = items.find(i => i.id === itemId);
            if (!item) continue;
            browser.contextMenus.create({
                id: `ffill-item-${item.id}`,
                parentId: `ffill-folder-${folder.id}`,
                title: item.key,
                contexts: ["editable"]
            });
        }
    }
}

// ── Context menu click handling ───────────────────────────────────────────────

browser.contextMenus.onClicked.addListener((info, tab) => {
    const menuItemId = String(info.menuItemId);
    if (!menuItemId.startsWith("ffill-item-")) return;

    const itemId = menuItemId.replace("ffill-item-", "");
    const item = formData.items.find(i => i.id === itemId);
    if (!item || tab?.id == null) return;

    browser.tabs.sendMessage(tab.id, {
        action: "fillField",
        value: item.value
    }).catch(err => console.error("FFill: sendMessage to content.js failed", err));
});

// ── Lifecycle ─────────────────────────────────────────────────────────────────

// Fetch on first install and each time the service worker wakes up
browser.runtime.onInstalled.addListener(() => fetchFormData());
browser.runtime.onStartup.addListener(() => fetchFormData());
