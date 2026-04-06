// background.js — FFill Safari Web Extension
//
// Responsibilities:
//   1. On install/startup, fetch FormItems + Folders from the native app via native messaging.
//   2. Persist fetched data to browser.storage.local so it survives service worker termination.
//   3. Build a "FFill" context menu tree:
//        FFill (root)
//          ├── ungrouped items (no folder)
//          ├── ── separator (if both ungrouped items and folders exist)
//          └── folder submenus → their items
//   4. On context menu item click, restore data from storage if the SW was terminated,
//      then send { action: "fillField", value } to the active tab's content.js.
//
// MV3 service workers are terminated after ~30s of inactivity. All in-memory state is
// lost on termination. Context menu entries persist (stored by Safari), but formData
// does not — hence the storage.local round-trip.

const APP_BUNDLE_ID = "vanija-dev.FFill";
const STORAGE_KEY = "ffillFormData";

// In-memory cache — populated on startup and restored from storage on wake-up.
let formData = { items: [], folders: [] };

// ── Storage helpers ───────────────────────────────────────────────────────────

async function saveToStorage() {
    await browser.storage.local.set({ [STORAGE_KEY]: formData });
}

/** Restores formData from storage. Returns true if data was found. */
async function restoreFromStorage() {
    const result = await browser.storage.local.get(STORAGE_KEY);
    if (result[STORAGE_KEY]) {
        formData = result[STORAGE_KEY];
        return true;
    }
    return false;
}

// ── Native messaging ──────────────────────────────────────────────────────────

/**
 * Ask the native Swift app for all FormItems and Folders.
 * On success: caches in memory, persists to storage, rebuilds context menus.
 */
async function fetchFormData() {
    try {
        const response = await browser.runtime.sendNativeMessage(
            APP_BUNDLE_ID,
            { action: "getFormData" }
        );

        if (response?.success && response.data) {
            formData = response.data;
            await saveToStorage();
            await rebuildMenus();
        } else {
            console.error("FFill: native app returned failure", response?.error ?? "(no detail)");
        }
    } catch (err) {
        console.error("FFill: sendNativeMessage error", err);
    }
}

// ── Context menu management ───────────────────────────────────────────────────

function rebuildMenus() {
    return new Promise((resolve) => {
        browser.contextMenus.removeAll(() => {
            buildMenus();
            resolve();
        });
    });
}

function buildMenus() {
    const { items, folders } = formData;

    // Root entry — always created so users see "FFill" in the menu
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

browser.contextMenus.onClicked.addListener(async (info, tab) => {
    const menuItemId = String(info.menuItemId);
    if (!menuItemId.startsWith("ffill-item-")) return;

    // Service worker may have been terminated and formData reset to empty.
    // Restore from storage.local first; fall back to a native fetch if storage is also empty.
    if (formData.items.length === 0) {
        const restored = await restoreFromStorage();
        if (!restored) {
            await fetchFormData();
        }
    }

    const itemId = menuItemId.replace("ffill-item-", "");
    const item = formData.items.find(i => i.id === itemId);
    if (!item || tab?.id == null) return;

    browser.tabs.sendMessage(tab.id, {
        action: "fillField",
        value: item.value
    }).catch(err => console.error("FFill: sendMessage to content.js failed", err));
});

// ── Lifecycle ─────────────────────────────────────────────────────────────────

// Fetch fresh data from native on first install and each Safari startup.
browser.runtime.onInstalled.addListener(() => fetchFormData());
browser.runtime.onStartup.addListener(() => fetchFormData());
