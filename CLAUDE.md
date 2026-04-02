# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Keep your replies extremely concise and focus on conveying the key information. No unnecessary fluff, no ling code snippets. 

## Project Overview

TempBox is a disposable email generator app for iOS, macOS, and iPadOS that uses the [mail.tm](https://mail.tm) service as its backend. Users can create temporary email addresses, receive messages, and manage them across platforms.

- **Platforms:** iOS 18+, macOS 14+, iPadOS 17+
- **No external dependencies** — uses only native Apple frameworks (SwiftUI, SwiftData, StoreKit, WebKit, BackgroundTasks)

## Build & Development

This is an Xcode project — there are no CLI build scripts or test runners. Development is done via Xcode.

- **Build:** Open `TempBox.xcodeproj` in Xcode and build with ⌘B
- **Run Tests:** ⌘U in Xcode, or target `TempBoxTests` / `TempBoxUITests`
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
| `AddressesController` | Core: fetches/syncs addresses and messages, manages SwiftData |
| `AppController` | Global UI state: accent color, onboarding, navigation path |
| `MailTMService` | All HTTP calls to mail.tm API (auth, accounts, messages, attachments) |
| `IAPManager` | StoreKit 2 in-app purchases for premium features |

`AddressesController` is the heaviest file — it coordinates between `MailTMService` and SwiftData, handles upsert logic, and drives message fetch cycles.

### SwiftData Models

- `Address` — persisted email address, versioned schema (`AddressMigrationPlan`)
- Messages are stored as SwiftData entities related to `Address`
- `AddressMigrationPlan.swift` manages schema migrations — add new versions here when changing model fields

### Navigation

- **iPhone:** `NavigationStack` in `ContentView`
- **iPad/Mac:** `NavigationSplitView` in `ContentView`
- Platform-specific UI uses `#if os(iOS)` / `#if os(macOS)` throughout

### View Organization

Each major screen has its own folder under `Views/` containing the view, its `ViewModel`, and sub-views (e.g. `MessagesView/MessagesView.swift`, `MessagesView/MessagesViewModel.swift`).

Shared UI components live in `Shared/Views/`. Reusable utilities (file I/O, base64, export formats) live in `Services/`.

### Import/Export & Legacy Migration

`ContentView` runs a one-time migration from the legacy Flutter-era data format on first launch. `ImportExport.swift` defines the versioned export schemas (`ExportVersionOne`, `ExportVersionTwo`). `ImportExportService` handles encode/decode.

### Background Email Service

`Background/` contains `BackgroundEmailService.swift` and `LiveEmailPoller.swift`. This feature is currently partially implemented (some code is commented out). The entitlements and background task identifiers are already configured.

### Premium Features (IAP)

Custom accent colors and app icons are gated behind in-app purchases managed by `IAPManager`. `TipJarView` presents the purchase UI. Color/icon selection lives in `SettingsView/AccentColor/` and `SettingsView/AppIconView`.
