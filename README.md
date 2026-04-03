# FFill

A macOS app + Safari Web Extension that speeds up form filling with preset, categorized data.

Inspired by [SimpleFill](https://simplefillapp.com/). Built for people who repeatedly fill out the same forms (job applications, registrations, etc.) and want a faster way to insert saved data via Safari's right-click context menu.

## How It Works

1. Open the **FFill** macOS app and save your data as key-value pairs (e.g., `First Name` = `John`).
2. Organize items into **folders** (e.g., "Personal", "Work").
3. In **Safari**, right-click any input field.
4. Select **FFill** from the context menu, pick a data item.
5. The field is filled instantly.

See [USER_JOURNEY.md](USER_JOURNEY.md) for the complete usage guide.

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
| `items` | `[FormItem]` | Items in this folder (deleteRule: `.nullify`) |
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
2. Caches items + folders in memory
3. Builds context menu: "FFill" root → ungrouped items → separator → folder submenus
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
    ├── FolderListView (list + drag reorder + add/edit/delete)
    │   ├── FolderRowView (name + item count)
    │   ├── FolderEditorView (sheet: folder name)
    │   └── FolderDetailView (items in folder, drag reorder)
    │
    └── SettingsView
        ├── Extension enable instructions
        ├── "Open Safari Extension Preferences" button
        └── Import/Export (JSON)
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
│       ├── Constants.swift
│       └── ImportExportService.swift
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
│   ├── ModelTests.swift
│   ├── ImportExportTests.swift
│   └── ExtensionHandlerTests.swift
│
├── PROGRESS.md
└── USER_JOURNEY.md
```

**Shared files** (target membership on both App and Extension targets):
- `Models/FormItem.swift`
- `Models/Folder.swift`
- `Models/SharedContainer.swift`
- `Utilities/Constants.swift`

---

## Testing

| Layer | Framework | What's Tested |
|-------|-----------|---------------|
| SwiftData models | XCTest | CRUD operations, relationships, sortOrder recalculation |
| ImportExportService | XCTest | JSON round-trip serialization, edge cases |
| SafariWebExtensionHandler | XCTest | Mock NSExtensionContext, verify response format |
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
| 6 | Settings & Polish | Import/export, extension instructions, app icons |
| 7 | Edge Cases | Empty states, framework compat, data refresh |

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

## Import/Export Format

```json
{
    "version": 1,
    "folders": [
        { "id": "uuid", "name": "Personal", "sortOrder": 0 }
    ],
    "items": [
        {
            "id": "uuid",
            "key": "First Name",
            "value": "John",
            "sortOrder": 0,
            "isRichText": false,
            "folderId": "uuid-or-null"
        }
    ]
}
```
