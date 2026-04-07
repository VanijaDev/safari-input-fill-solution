## FFill

A macOS app + Safari Web Extension that speeds up form filling with preset, categorized data.

Built for people who repeatedly fill out the same forms (job applications, registrations, etc.) and want a faster way to insert saved data via Safari's right-click context menu.

## How It Works

1. Open the **FFill** macOS app and save your data as key-value pairs (e.g., `First Name` = `John`).
2. Organize items into **folders** (e.g., "Personal", "Work") — folders can be nested inside each other.
3. In **Safari**, right-click any input field.
4. Select **FFill** from the context menu, pick a data item.
5. The field is filled instantly.

See [USER_JOURNEY.md](USER_JOURNEY.md) for the complete usage guide.

---

## Getting Started (for new users)

> **Requirements:** macOS 26 (Tahoe) or later · Xcode 26 or later · A free Apple ID (no paid developer account needed)

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/safari-input-fill-solution.git
cd safari-input-fill-solution/FFill
open FFill.xcodeproj
```

### 2. Choose your own identifiers

The project ships with the original author's bundle IDs. You must replace them with your own before building — Xcode signing requires each developer to use a unique identifier tied to their Apple ID.

Pick a reverse-domain prefix, e.g. `com.yourname` or `io.yourname`. You'll use it in three places:

**a) `FFill/Utilities/Constants.swift`** — change the App Group ID:
```swift
// Before:
static let appGroupID = "group.vanija-dev.FFill"

// After (use your own prefix):
static let appGroupID = "group.yourname.FFill"
```

**b) Xcode project settings** — change the Bundle Identifier for both targets:

| Target | Original | Change to |
|--------|----------|-----------|
| FFill | `vanija-dev.FFill` | `yourname.FFill` |
| FFill Extension | `vanija-dev.FFill.Extension` | `yourname.FFill.Extension` |

To update: select the project in the navigator → click each target → **General** tab → change **Bundle Identifier**.

**c) Both entitlement files** — update the App Group ID to match step (a):

- `FFill/FFill.entitlements`
- `FFill Extension/FFill Extension.entitlements`

In each file, change:
```xml
<string>group.vanija-dev.FFill</string>
```
to:
```xml
<string>group.yourname.FFill</string>
```

### 3. Configure signing

1. In Xcode, select the **FFill** project in the navigator
2. For **each target** (FFill and FFill Extension):
   - Go to **Signing & Capabilities** tab
   - Check **Automatically manage signing**
   - Set **Team** to your Apple ID (add it via Xcode → Settings → Accounts if needed)
3. Xcode will create a free provisioning profile automatically

> A free Apple ID is sufficient for running the app on your own Mac. You do **not** need a paid Apple Developer account.

### 4. Add the App Group entitlement

Because you changed the App Group ID, Xcode needs to register it:

1. Select the **FFill** target → **Signing & Capabilities**
2. If **App Groups** capability is missing, click **+** and add it
3. Set the group to `group.yourname.FFill` (your prefix from step 2a)
4. Repeat for the **FFill Extension** target

### 5. Build and run

1. Select the **FFill** scheme and **My Mac** as the destination
2. Press **Cmd+R** to build and run

### 6. Enable the extension in Safari

1. Open **Safari → Settings → Extensions**
2. Enable **FFill**
3. Under **"Allow FFill to read and alter webpages"** → select **Allow on All Websites**

### 7. Use it

1. Add items in the FFill app (name, email, address, etc.)
2. In Safari, right-click any input field → **FFill** → select an item
3. After adding new items, click the FFill toolbar icon and press **Refresh Menu**

---

## Documentation

| File | Purpose |
|------|---------|
| [README.md](README.md) | Architecture, data models, extension protocol, project structure |
| [CLAUDE.md](CLAUDE.md) | Instructions for Claude (AI assistant) — build commands, code style, rules |
| [PROGRESS.md](PROGRESS.md) | Phase-by-phase implementation checklist (source of truth for status) |
| [USER_JOURNEY.md](USER_JOURNEY.md) | End-user flows and usage examples |

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| macOS App UI | SwiftUI |
| Data Persistence | SwiftData |
| Browser Integration | Safari Web Extension (Manifest V3) |
| Native Messaging | NSExtensionRequestHandling |
| Minimum Target | macOS 26 Tahoe |

---

## Architecture

Two Xcode targets sharing data via **App Groups**:

```
FFill (macOS App)                    FFill Extension (Safari Web Extension)
┌─────────────────────┐              ┌──────────────────────────────────┐
│  SwiftUI Views      │              │  manifest.json                   │
│  - Form Data CRUD   │              │  background.js (context menus)   │
│  - Folder Management│   App Group  │  content.js (field filling)      │
│  - Settings         │◄────────────►│  SafariWebExtensionHandler.swift │
│  - Import/Export    │  (shared     │    (reads SwiftData, returns     │
│                     │   SwiftData) │     data to JS via native msg)   │
│  SwiftData Store    │              │                                  │
└─────────────────────┘              └──────────────────────────────────┘
```

### Data Flow (filling a field)

```
User right-clicks input in Safari
  → Safari shows "FFill" context menu (built by background.js)
  → User clicks an item (e.g., "First Name")
  → background.js sends { action: "fillField", value: "John" } to content.js
  → content.js sets the input's value using native setter + dispatches events
  → Field is filled
```

### Data Flow (loading menu data)

```
Extension service worker starts
  → background.js calls browser.runtime.sendNativeMessage({ action: "getFormData" })
  → SafariWebExtensionHandler.swift reads from shared SwiftData store
  → Returns serialized items + folders as JSON
  → background.js builds context menu tree
```

---

## Data Models

### FormItem
| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `key` | `String` | Label shown in context menu (e.g., "First Name") |
| `value` | `String` | Value inserted into the field (e.g., "John") |
| `sortOrder` | `Int` | Controls display order in menu and app |
| `isRichText` | `Bool` | Whether value contains rich text |
| `folder` | `Folder?` | Optional folder assignment (inverse: `Folder.items`) |
| `createdAt` | `Date` | Creation timestamp |
| `updatedAt` | `Date` | Last modified timestamp |

### Folder
| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `name` | `String` | Folder name (e.g., "Personal") |
| `sortOrder` | `Int` | Controls display order |
| `items` | `[FormItem]` | Items directly in this folder (deleteRule: `.nullify`) |
| `parent` | `Folder?` | Optional parent folder; becomes `nil` when parent is deleted |
| `children` | `[Folder]` | Sub-folders nested inside this folder (deleteRule: `.nullify`) |
| `fullPath` | `String` | Computed — slash-separated path from root, e.g. "Work / Engineering" |
| `descendantIDs()` | `Set<UUID>` | Recursive helper — all descendant folder IDs; used to prevent parent-picker cycles |
| `createdAt` | `Date` | Creation timestamp |

### SharedContainer
- App Group ID: `group.vanija-dev.FFill`
- Shared `ModelContainer` with explicit URL in App Group container directory
- Used by both the macOS app and the extension handler

---

## Safari Web Extension

### manifest.json
- Manifest V3
- Permissions: `contextMenus`, `activeTab`, `nativeMessaging`
- Service worker: `background.js`
- Content script: `content.js` (matches `<all_urls>`, runs at `document_idle`)

### background.js
1. On startup: fetches all form data from native app via `browser.runtime.sendNativeMessage()`
2. Caches items + folders in `browser.storage.local` (survives service worker termination)
3. Builds context menu: "FFill" root → ungrouped items → separator → folder submenus (arbitrarily nested via recursive `createFolderMenu()`)
4. On menu click: sends `{ action: "fillField", value }` to content script

### content.js
- Listens for `fillField` messages
- Uses native input setter (`HTMLInputElement.prototype.value.set`) for React/Vue compatibility
- Dispatches `input` + `change` events to trigger framework change detection
- Supports `<input>`, `<textarea>`, and `contentEditable` elements

### SafariWebExtensionHandler.swift
- Implements `NSExtensionRequestHandling`
- Creates `ModelContext` from shared `ModelContainer`
- Fetches all `FormItem` and `Folder` records sorted by `sortOrder`
- Serializes to JSON-safe dictionaries, responds via `NSExtensionContext`

---

## macOS App Views

```
FFillApp (@main, modelContainer: SharedContainer.modelContainer)
└── ContentView (NavigationSplitView)
    ├── SidebarView
    │   ├── Form Data
    │   ├── Folders
    │   └── Settings
    │
    ├── FormDataListView (list + drag reorder + add/edit/delete)
    │   ├── FormItemRowView (key + value preview + folder badge)
    │   └── FormItemEditorView (sheet: key, value, folder picker)
    │
    ├── FolderListView (root-level folders only + drag reorder + add/edit/delete)
    │   ├── FolderRowView (name + sub-folder/item count summary)
    │   ├── FolderEditorView (sheet: folder name + parent folder picker with cycle prevention)
    │   └── FolderDetailView (sub-folders section + items section, drag reorder each)
    │
    └── SettingsView (Delete All Data)
```

---

## Project Structure

```
FFill/
├── FFill/                              # macOS App target
│   ├── FFillApp.swift
│   ├── Info.plist
│   ├── FFill.entitlements
│   ├── Assets.xcassets/
│   ├── Models/
│   │   ├── FormItem.swift
│   │   ├── Folder.swift
│   │   └── SharedContainer.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── Sidebar/SidebarView.swift
│   │   ├── FormData/
│   │   │   ├── FormDataListView.swift
│   │   │   ├── FormItemRowView.swift
│   │   │   └── FormItemEditorView.swift
│   │   ├── Folders/
│   │   │   ├── FolderListView.swift
│   │   │   ├── FolderRowView.swift
│   │   │   ├── FolderEditorView.swift
│   │   │   └── FolderDetailView.swift
│   │   └── Settings/SettingsView.swift
│   └── Utilities/
│       └── Constants.swift
│
├── FFill Extension/                    # Safari Web Extension target
│   ├── Info.plist
│   ├── FFill Extension.entitlements
│   ├── SafariWebExtensionHandler.swift
│   └── Resources/
│       ├── manifest.json
│       ├── background.js
│       ├── content.js
│       └── images/
│
├── FFillTests/                         # Unit tests
│   └── FFillTests.swift
│
├── PROGRESS.md
└── USER_JOURNEY.md
```

**Shared files** (target membership on both App and Extension targets):
- `Models/FormItem.swift`
- `Models/Folder.swift`
- `Models/SharedContainer.swift`
- `Models/ExtensionDataService.swift`
- `Utilities/Constants.swift`

---

## Testing

| Layer | Framework | What's Tested |
|-------|-----------|---------------|
| SwiftData models | Swift Testing | CRUD operations, relationships, sortOrder recalculation |
| ExtensionDataService | Swift Testing | JSON serialization, sortOrder, folder relationships |
| background.js | Manual / Jest | Context menu tree construction from data |
| content.js | Manual / Jest | Field filling, event dispatch, framework compat |

---

## Implementation Phases

Development is **gradual** — each phase is implemented, reviewed, and verified before moving to the next. See [PROGRESS.md](PROGRESS.md) for the detailed checklist.

| Phase | What | Key Deliverable |
|-------|------|-----------------|
| 1 | Project Scaffolding | Xcode project with both targets, entitlements, App Groups |
| 2 | Data Models | SwiftData models + shared container + unit tests |
| 3 | App UI (CRUD) | Full form data and folder management UI |
| 4 | Drag-and-Drop | Reordering items and folders with persistent sort order |
| 5 | Safari Extension | Context menu + field filling, end-to-end working |
| 6 | Edge Cases & Refinement | Confirmation dialogs, data refresh popup, empty states |

---

## Entitlements

Both targets require the same App Groups entitlement:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.vanija-dev.FFill</string>
</array>
```

---

## Native Messaging Protocol

| Direction | Method | Payload | Response |
|-----------|--------|---------|----------|
| JS → Native | `browser.runtime.sendNativeMessage()` | `{ "action": "getFormData" }` | `{ "success": true, "data": { "items": [...], "folders": [...] } }` |
| JS → Content | `browser.tabs.sendMessage()` | `{ "action": "fillField", "value": "John" }` | `{ "success": true }` |

---

