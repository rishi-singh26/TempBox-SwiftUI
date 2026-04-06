# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Keep your replies extremely concise and focus on conveying the key information. No unnecessary fluff, no long code snippets. 

## Project Overview

TempBox is a disposable email generator app for iOS, macOS, and iPadOS that uses the [mail.tm](https://mail.tm) service as its backend. Users can create temporary email addresses, receive messages, and manage them across platforms.

- **Platforms:** iOS 18+, macOS 14+, iPadOS 17+
- **No external dependencies** — uses only native Apple frameworks (SwiftUI, SwiftData, StoreKit, WebKit, BackgroundTasks)

## Build & Development

This is an Xcode project — there are no CLI build scripts or test runners. Development is done via Xcode.

- **Build:** Open `TempBox.xcodeproj` in Xcode and build with ⌘B
- **Run Tests:** ⌘U in Xcode, or target `TempBoxTests` / `TempBoxUITests` — note these targets currently contain only stub/empty test cases, no real coverage exists
- **StoreKit Testing:** Use `TempBox.storekit` configuration for local IAP testing

## Architecture

The app uses MVVM with SwiftUI and SwiftData for persistence.

### Data Flow

```
mail.tm REST API
    → MailTMService (HTTP layer, async/await)
    → AddressesController (business logic, owns SwiftData context)
    → SwiftData (local SQLite via ModelContainer)
    → Views via @EnvironmentObject / @Query
```

### Key Controllers (injected as `@EnvironmentObject`)

| Controller | Role |
|---|---|
| `AddressesController` | Core: fetches/syncs addresses and messages, manages SwiftData upserts |
| `AppController` | Global UI state: accent color, onboarding, navigation path |
| `MailTMService` | All HTTP calls to mail.tm API (auth, accounts, messages, attachments) |
| `IAPManager` | StoreKit 2 in-app purchases for premium features |
| `RemoteDataManager` | Fetches GitHub-hosted remote config (update notices, icon preview data) |

`AddressesController` is the heaviest file — it coordinates between `MailTMService` and SwiftData, handles upsert logic, and drives message fetch cycles. All controllers are `@MainActor` and use `async/await` throughout.

### SwiftData Models

- `Address` — persisted email account; schema is at **V4** (`AddressMigrationPlan` has 3 migration stages: V1→V2, V2→V3, V3→V4)
- `Message` — email entity with a many-to-one relationship to `Address` (cascade delete)
- `Folder` — organizational container with a one-to-many relationship to `Address` (nullify on delete)
- Add new schema versions to `AddressMigrationPlan.swift` when changing model fields

### Navigation

- **iPhone:** `NavigationStack` in `ContentView`; `DeviceType` enum distinguishes iPhone vs iPad routing
- **iPad:** `NavigationSplitView` (.doubleColumn)
- **Mac:** `NavigationSplitView` (3-column)
- Platform-specific UI uses `#if os(iOS)` / `#if os(macOS)` throughout
- A special `Address` with `id == KUnifiedInboxId` represents the unified inbox view (all addresses aggregated)

### View Organization

Each major screen has its own folder under `Views/` containing the view, its `ViewModel`, and sub-views (e.g. `MessagesView/MessagesView.swift`, `MessagesView/MessagesViewModel.swift`).

Shared UI components live in `Shared/Views/`. Reusable utilities (file I/O, base64, export formats) live in `Services/`. `Extensions/` augments standard types: `StringExtensions` generates random usernames/passwords, `ColorExtension` provides `Color(hex:)`/`toHex()`, `DateExtensions` handles ISO8601 parsing.

### Import/Export & Legacy Migration

`ContentView` runs a one-time migration from the legacy Flutter-era data format on first launch. `ImportExport.swift` defines the versioned export schemas (`ExportVersionOne`, `ExportVersionTwo`). `ImportExportService` handles encode/decode.

### Background Email Service

Background email service is planned but **not yet implemented** — no source files exist for it yet, though the entitlements and background task identifiers are already configured in the project.

### Premium Features (IAP)

Custom accent colors and app icons are gated behind in-app purchases managed by `IAPManager`. `TipJarView` presents the purchase UI. Color/icon selection lives in `SettingsView/AccentColor/` and `SettingsView/AppIconView`.
