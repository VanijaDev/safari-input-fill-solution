# FFill - Claude Instructions

## Project Overview
macOS app + Safari Web Extension for fast form filling with preset data. See @README.md for full architecture and @USER_JOURNEY.md for user flows.

## Tech Stack
- SwiftUI + SwiftData (macOS 26 Tahoe+)
- Safari Web Extension (Manifest V3, JS)
- App Group: `group.vanija-dev.FFill`
- Bundle ID: `vanija-dev.FFill` (app), `vanija-dev.FFill.Extension` (extension)

## Project Structure
- `FFill/FFill/` — macOS app target (currently AppDelegate + Storyboard, needs conversion to SwiftUI App lifecycle)
- `FFill/FFill Extension/` — Safari Web Extension target
- `FFill/FFill Extension/Resources/` — manifest.json, background.js, content.js, popup files
- `FFill/FFill Extension/SafariWebExtensionHandler.swift` — native messaging bridge between JS and Swift
- Shared files (Models, Constants) must have target membership on BOTH targets

## Build & Run
- Open `FFill/FFill.xcodeproj` in Xcode 26
- Select "FFill" scheme, target "My Mac"
- Cmd+R to build and run
- Enable extension: Safari > Settings > Extensions > FFill

## Code Style
- Use Swift modern concurrency patterns
- SwiftUI views should be small and composable
- SwiftData models use `@Model` macro
- JS files use ES modules (manifest declares `"type": "module"`)
- No third-party dependencies — Apple frameworks only

## Architecture Rules
- Data sharing between app and extension uses App Groups (`group.vanija-dev.FFill`)
- SharedContainer.swift provides the shared ModelContainer — both targets must use it
- SafariWebExtensionHandler reads SwiftData and returns JSON to JS via NSExtensionContext
- background.js builds context menus from native message data, content.js fills fields
- Use native input setter (`HTMLInputElement.prototype.value.set`) for React/Vue compatibility in content.js

## IMPORTANT: Progress Tracking
After completing ANY task, immediately update PROGRESS.md:
- Mark completed items with `[x]`
- Add notes about decisions made or issues encountered
- Mark phase headings with `(COMPLETED)` when all items are done
- PROGRESS.md is the single source of truth — never leave it stale

## Development Workflow
- Implement one phase at a time (see @PROGRESS.md for current status)
- After each phase: stop, explain changes, wait for review before continuing
- Convert app from AppDelegate/Storyboard to SwiftUI App lifecycle in Phase 2
- When creating shared model files, set target membership on both FFill and FFill Extension targets

## Testing
- Use XCTest for Swift unit tests (models, import/export, extension handler)
- Test FormItem and Folder CRUD, relationships, and sortOrder recalculation
- Test ImportExportService JSON round-trip serialization
- JS tests for background.js menu construction and content.js field filling

## Common Gotchas
- The template generated AppDelegate + Storyboard — this must be converted to SwiftUI `@main struct FFillApp: App` in Phase 2
- App Group container URL must be set explicitly in ModelConfiguration, or the app and extension will use separate databases
- SafariWebExtensionHandler runs on a background thread — create a new ModelContext per request, don't share across threads
- Safari context menus require the `contextMenus` permission in manifest.json
- Content script `matches` is currently `*://example.com/*` — must be changed to `<all_urls>`
