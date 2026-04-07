# FFill - Implementation Progress

## Tech Stack
- **SwiftUI** + **SwiftData** + **Safari Web Extension** (Manifest V3)
- **Target**: macOS 26 Tahoe+

## Development Approach
> **Gradual, guided development.** After each phase, Claude will stop and walk you through what was implemented, explain the key decisions, and let you review before moving on. No phase starts until the previous one is understood and approved.
>
> **Workflow:** Use **Xcode 26 with built-in Claude** for all coding, building, and running. Use this repo's documentation (README.md, USER_JOURNEY.md, PROGRESS.md) as context for Claude in Xcode. Phase 1 (project scaffolding) is done manually in Xcode with step-by-step guidance.

## IMPORTANT: Rules for Claude (in any environment)
> **Keep PROGRESS.md in sync at all times.** After completing any task, immediately update this file:
> - Mark completed items with `[x]`
> - Add relevant notes (actual file names, decisions made, issues encountered)
> - When a phase is fully done, mark the heading with `(COMPLETED)`
> - Never leave this file stale — it is the single source of truth for project progress

---

## Phase 1: Project Scaffolding ✅
> *Done manually in Xcode with Claude guidance.*

- [x] Create Xcode project via Safari Extension App template (macOS, Safari Web Extension, Swift)
- [x] Add App Groups entitlement to both targets (`group.vanija-dev.FFill`)
- [x] Set deployment target: macOS 26.4 (Tahoe)
- [x] Verify file structure: FFill (app) + FFill Extension (web extension) targets
- [x] **Checkpoint:** Project verified — correct template, entitlements, signing configured.

> **Note:** Bundle ID is `vanija-dev.FFill`, extension bundle ID is `vanija-dev.FFill.Extension`. Team: Ivan Solomichev (Personal Team). The template generated AppDelegate + Storyboard — conversion to SwiftUI App lifecycle will happen in Phase 2.

## Phase 2: Data Models ✅

> **Implementation notes:**
> - Replace `AppDelegate.swift` + `Main.storyboard` + `ViewController.swift` with `FFillApp.swift` (SwiftUI `@main struct FFillApp: App`) — the template generated the old lifecycle, Phase 2 converts it
> - Model files (`FormItem.swift`, `Folder.swift`, `SharedContainer.swift`, `Constants.swift`) must have target membership on **both** the `FFill` app target AND the `FFill Extension` target — without this the extension cannot access the models
> - `SharedContainer` must set an explicit file URL inside the App Group container directory (`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`), NOT the default location — otherwise app and extension will use separate, isolated databases and the extension will see no data

- [x] Create `Constants.swift` with App Group ID (`FFill/FFill/Utilities/Constants.swift`)
- [x] Create `FormItem.swift` SwiftData model (`FFill/FFill/Models/FormItem.swift`)
- [x] Create `Folder.swift` SwiftData model (`FFill/FFill/Models/Folder.swift`)
- [x] Create `SharedContainer.swift` — shared ModelContainer factory using explicit App Group URL (`FFill/FFill/Models/SharedContainer.swift`)
- [x] Set target membership of model files to both targets (FFill + FFill Extension) — verified via File Inspector
- [x] Replace AppDelegate/Storyboard with `FFillApp.swift` (SwiftUI App lifecycle) + placeholder `ContentView.swift`; deleted AppDelegate.swift, ViewController.swift, Main.storyboard, and template web resources
- [x] **Tests:** Unit tests for FormItem and Folder CRUD, relationships, sortOrder - 16/16 passing (`FFillTests/FFillTests.swift`)
- **Checkpoint:** Build verified ✅ — project compiles. All 16 model tests pass.

## Phase 3: App UI (CRUD) ✅
- [x] Build `SidebarView` with navigation links (Form Data, Folders, Settings)
- [x] Build `ContentView` with NavigationSplitView (2-column: sidebar + NavigationStack detail)
- [x] Build `FormDataListView` — list all items with add/edit/delete + empty state
- [x] Build `FormItemRowView` — key (bold) + value preview + folder badge (capsule)
- [x] Build `FormItemEditorView` — sheet: key, value (multi-line), folder picker, rich-text toggle
- [x] Build `FolderListView` — list all folders with add/edit/delete + drill-in via NavigationLink
- [x] Build `FolderRowView` — folder name + item count
- [x] Build `FolderEditorView` — sheet: folder name
- [x] Build `FolderDetailView` — items in folder with edit/delete; empty state placeholder
- [x] Add `SettingsView` placeholder (full implementation Phase 6)
- **Checkpoint:** Build verified ✅ — project compiles. Run the app to test CRUD.

## Phase 4: Drag-and-Drop Reordering ✅
- [x] Add `.onMove` to FormDataListView with sortOrder update logic
- [x] Add `.onMove` to FolderListView with sortOrder update logic
- [x] Add `.onMove` to FolderDetailView with sortOrder update logic
- [x] **Tests:** 5 new tests in `SortOrderReorderingTests` suite — 21/21 passing total
- **Checkpoint:** Build verified ✅ — all tests pass. Run app to drag items and verify order persists.

## Phase 5: Safari Web Extension ✅
- [x] Implement `SafariWebExtensionHandler.swift` — delegates to `ExtensionDataService.buildResponsePayload()`, handles unknown actions with error response
- [x] Create `ExtensionDataService.swift` (dual target: FFill + FFill Extension) — serializes SwiftData models to JSON-compatible dict; extracted for unit testability without importing SafariServices
- [x] Write `manifest.json` — added `contextMenus`, `activeTab`, `tabs`, `nativeMessaging` permissions; changed `content_scripts.matches` from `*://example.com/*` to `<all_urls>`; added `run_at: document_idle`
- [x] Write `background.js` — fetches native data on `onInstalled`/`onStartup`; builds context menu tree (FFill root → ungrouped items → separator → folder submenus); sends `fillField` to content.js on click
- [x] Write `content.js` — tracks right-clicked element via `contextmenu` event; fills using native setter trick (`Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set`) for React/Vue/Angular compatibility; dispatches `input` + `change` events
- [x] **Tests:** 6 new `ExtensionDataServiceTests` — empty store, ungrouped items (no folderId key), sortOrder, folderId presence, folder itemIds order, multi-folder sort — 27/27 passing total
- [ ] **Tests:** JS tests for background.js / content.js (require external test runner such as Jest — not planned)

> **Notes:**
> - `ExtensionDataService.swift` must have target membership on both `FFill` and `FFill Extension` — without this the extension won't compile
> - Safari requires explicit "Allow on All Websites" permission for content script injection — without this, the context menu appears but filling doesn't work
> - Both `export` keywords were removed from `buildMenus()` (background.js) and `fillField()` (content.js) — content scripts cannot be ES modules in MV3; background.js is a module but exports serve no purpose at runtime
> - The `folderId` key is omitted entirely (not `null`) for ungrouped items — JS `!item.folderId` handles both `null` and `undefined` as falsy
> - `"tabs"` permission added alongside `"activeTab"` to ensure `browser.tabs.sendMessage` works in Safari

- [x] Fix service worker termination bug — `formData` now persisted to `browser.storage.local`; restored on SW wake-up before processing click events; `"storage"` permission added to manifest

- **Checkpoint:** ✅ End-to-end verified — right-click any input on any site, select FFill item, field populates correctly including folder submenus. Verified working after 2+ minutes of inactivity (SW termination).

## Phase 6: Edge Cases & Refinement ✅
- [x] Handle empty states with placeholder views — already implemented in Phase 3 for all three list views
- [x] Add confirmation dialogs for destructive actions — `.alert` added to context menu Delete in `FormDataListView`, `FolderListView`, `FolderDetailView`; folder delete message clarifies items are unassigned not deleted
- [x] Handle extension data staleness (refresh mechanism) — toolbar popup (`popup.html` / `popup.js`) with "Refresh Menu" button; sends `{ action: "refresh" }` to background.js which re-fetches from native and rebuilds context menus; shows item count on success
- [x] Test with React/Vue/Angular sites — native setter trick confirmed working (verified in Phase 5 on React-based job application forms)
- [x] Test with contentEditable elements — `fillField()` in content.js handles `isContentEditable` via `textContent` assignment
- [x] Add "Delete All Data" button to `SettingsView` — destructive button with confirmation alert showing exact item/folder counts; disabled when store is already empty; deletes all `FormItem` and `Folder` records in one pass
- [x] **Tests:** `SettingsTests` suite — delete all clears store, delete all with mixed data, button disabled when empty — 30/30 passing total

> **Notes:**
> - Swipe-to-delete remains immediate (no dialog) — it's a deliberate gesture; confirmation is on context menu Delete only
> - After adding/editing items in the macOS app, click the FFill toolbar icon in Safari and press "Refresh Menu" to update the context menu
> - After "Delete All Data", also press "Refresh Menu" in the Safari popup to clear the extension's context menu cache

- **Checkpoint:** Build verified ✅ — 30/30 tests passing. Confirmation dialogs, refresh popup, empty states, and delete-all implemented.

---

## Post-Phase 6 Improvements ✅

### Value Text Alignment Fix
- [x] Replaced `TextField("Value", axis: .vertical)` with `LabeledContent("Value") { TextEditor(...) }` in `FormItemEditorView` — macOS `.formStyle(.grouped)` overrides text alignment for multi-line `TextField`, whereas `TextEditor` is always left-aligned by default

### Nested Folders (Sub-folder support)
- [x] **`Folder.swift`** — added `parent: Folder?` and `@Relationship(deleteRule: .nullify, inverse: \Folder.parent) var children: [Folder]`; delete rule `.nullify` means deleting a parent makes its children root-level (matching items behavior); added `fullPath` computed property (e.g. "Work / Engineering") and `descendantIDs()` recursive helper for cycle prevention in parent picker
- [x] **`FolderListView.swift`** — `@Query` filter changed to `#Predicate<Folder> { $0.parent == nil }` so only root-level folders appear at the top level
- [x] **`FolderDetailView.swift`** — added "Sub-folders" section showing `folder.children` sorted by `sortOrder`, with NavigationLink drill-in, context menu Edit/Delete, `.onDelete`, `.onMove`; added "Add Sub-folder" toolbar button; removed duplicate `.navigationDestination(for: Folder.self)` that caused a SwiftUI conflict (root declaration in `FolderListView` covers the entire stack)
- [x] **`FolderEditorView.swift`** — added parent folder `Picker` with `availableParents` computed property that excludes the editing folder and all its descendants (cycle prevention); pre-selects parent when opened via "Add Sub-folder"
- [x] **`FormItemEditorView.swift`** — folder picker now shows `folder.fullPath` instead of `folder.name` so nested paths (e.g. "Work / Engineering") are visible
- [x] **`ExtensionDataService.swift`** — folder serialization includes `parentId` for child folders; omitted entirely (not `null`) for root folders, matching the `folderId` pattern for items
- [x] **`background.js`** — `buildMenus()` now separates root and child folders; new `createFolderMenu(folder, parentMenuId, items, allFolders)` recursively builds arbitrarily-deep context menu submenus sorted by `sortOrder`

### FolderRowView Content Summary Fix
- [x] **`FolderRowView.swift`** — replaced hard-coded `folder.items.count` with `contentSummary` computed property that shows "N sub-folder(s)", "N item(s)", or "N sub-folder(s), N item(s)" based on what's non-zero; fixes top-level folders showing "0" when they contain only sub-folders

### Tests
- [x] **`NestedFolderTests` suite** (8 tests) — child/parent relationships, delete-parent-nullifies-children, three-level nesting traversal, `fullPath`, `descendantIDs()`, `ExtensionDataService` parentId inclusion, folder-with-only-sub-folders model behavior
- [x] **38/38 tests passing total**

> **Notes:**
> - SwiftData handles the new optional `parent`/`children` relationships as a lightweight migration — no versioned schema required
> - `.navigationDestination(for: Folder.self)` must appear exactly once per `NavigationStack`; placing it in `FolderListView` covers all nested drill-in levels automatically
> - The `fullPath` property walks up the `parent` chain recursively — keep nesting depth reasonable to avoid long menu labels

- **Checkpoint:** Build verified ✅ — 38/38 tests passing. Nested folders, value alignment, and count summary all working end-to-end.
