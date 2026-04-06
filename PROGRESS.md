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
- [ ] **Tests:** JS tests for background.js / content.js (require external test runner — deferred to Phase 7)

> **Notes:**
> - `ExtensionDataService.swift` must have target membership on both `FFill` and `FFill Extension` — without this the extension won't compile
> - Safari requires explicit "Allow on All Websites" permission for content script injection — without this, the context menu appears but filling doesn't work
> - Both `export` keywords were removed from `buildMenus()` (background.js) and `fillField()` (content.js) — content scripts cannot be ES modules in MV3; background.js is a module but exports serve no purpose at runtime
> - The `folderId` key is omitted entirely (not `null`) for ungrouped items — JS `!item.folderId` handles both `null` and `undefined` as falsy
> - `"tabs"` permission added alongside `"activeTab"` to ensure `browser.tabs.sendMessage` works in Safari

- **Checkpoint:** ✅ End-to-end verified — right-click any input on any site, select FFill item, field populates correctly including folder submenus.

## Phase 6: Settings & Polish
- [ ] Build `SettingsView` with extension enable instructions
- [ ] Add `SFSafariApplication.showPreferencesForExtension` button
- [ ] Implement `ImportExportService` (JSON export/import)
- [ ] **Tests:** Unit tests for ImportExportService (round-trip serialization)
- [ ] Add app icon assets
- **Checkpoint:** Export data, delete all items, re-import, verify everything restored.

## Phase 7: Edge Cases & Refinement
- [ ] Handle empty states with placeholder views
- [ ] Add confirmation dialogs for destructive actions
- [ ] Handle extension data staleness (refresh mechanism)
- [ ] Test with React/Vue/Angular sites
- [ ] Test with contentEditable elements
- **Checkpoint:** Final review. Test across multiple real-world job application sites.
