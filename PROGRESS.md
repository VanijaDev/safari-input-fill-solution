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

## Phase 1: Project Scaffolding (COMPLETED)
> *Done manually in Xcode with Claude guidance.*

- [x] Create Xcode project via Safari Extension App template (macOS, Safari Web Extension, Swift)
- [x] Add App Groups entitlement to both targets (`group.vanija-dev.FFill`)
- [x] Set deployment target: macOS 26.4 (Tahoe)
- [x] Verify file structure: FFill (app) + FFill Extension (web extension) targets
- [x] **Checkpoint:** Project verified — correct template, entitlements, signing configured.

> **Note:** Bundle ID is `vanija-dev.FFill`, extension bundle ID is `vanija-dev.FFill.Extension`. Team: Ivan Solomichev (Personal Team). The template generated AppDelegate + Storyboard — conversion to SwiftUI App lifecycle will happen in Phase 2.

## Phase 2: Data Models

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

## Phase 3: App UI (CRUD)
- [ ] Build `SidebarView` with navigation links (Form Data, Folders, Settings)
- [ ] Build `ContentView` with NavigationSplitView
- [ ] Build `FormDataListView` — list all items, delete support
- [ ] Build `FormItemRowView` — display row with key + value preview
- [ ] Build `FormItemEditorView` — add/edit items (key, value, folder picker)
- [ ] Build `FolderListView` — list all folders, delete support
- [ ] Build `FolderRowView` — display folder row
- [ ] Build `FolderEditorView` — add/edit folders
- [ ] Build `FolderDetailView` — show items in a folder
- **Checkpoint:** Run the app in Xcode. Add/edit/delete items and folders. Review UI together.

## Phase 4: Drag-and-Drop Reordering
- [ ] Add `.onMove` to FormDataListView with sortOrder update logic
- [ ] Add `.onMove` to FolderListView with sortOrder update logic
- [ ] Add drag-and-drop for items within FolderDetailView
- [ ] **Tests:** Unit tests for sortOrder recalculation after move
- **Checkpoint:** Run the app, drag items around, verify order persists after relaunch.

## Phase 5: Safari Web Extension
- [ ] Implement `SafariWebExtensionHandler.swift` — handle `getFormData` action
- [ ] Write `manifest.json` with contextMenus + nativeMessaging permissions
- [ ] Write `background.js` — native message fetch, menu building, click handling
- [ ] Write `content.js` — field filling with native setter trick
- [ ] **Tests:** Unit tests for SafariWebExtensionHandler (mock request/response)
- [ ] **Tests:** JS tests for background.js menu tree construction
- [ ] **Tests:** JS tests for content.js field filling logic
- **Checkpoint:** Enable extension in Safari, right-click an input field, fill it. Full end-to-end test.

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
