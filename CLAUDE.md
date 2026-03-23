# FinanceApp

Personal finance app for macOS 14+ and iOS 17+. Manages multiple accounts, transfers, income/expense tracking with categories. Syncs across devices via Supabase (PostgreSQL + Realtime + Apple Sign-In).

## Tech Stack

- **Swift 6.0** / **SwiftUI** / **SwiftData** (local persistence) / **Supabase** (remote sync + auth)
- **XcodeGen** (`project.yml` generates `FinanceApp.xcodeproj`)
- **Architecture**: MVVM — Views own `@State`, ViewModels hold business logic, Models are `@Model` classes
- **Supabase Swift SDK** v2 (SPM dependency)

## Build & Test

```bash
# Must set DEVELOPER_DIR (xcode-select points to CommandLineTools)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# macOS
xcodebuild build -project FinanceApp.xcodeproj -scheme FinanceApp-macOS -configuration Debug CODE_SIGNING_ALLOWED=NO

# iOS (simulator)
xcodebuild build -project FinanceApp.xcodeproj -scheme FinanceApp-iOS -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO

# Tests (macOS)
xcodebuild test -scheme FinanceApp-macOS -configuration Debug CODE_SIGNING_ALLOWED=NO

# Tests (iOS simulator)
xcodebuild test -scheme FinanceApp-iOS -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

After modifying `project.yml`, regenerate the Xcode project: `/opt/homebrew/bin/xcodegen generate`

## Project Structure

```
Sources/
├── FinanceApp.swift              # @main, ModelContainer + SyncEngine + AuthManager setup
├── Models/                       # @Model classes (Account, Transaction, Category, FinanceEnums)
│   └── (SyncMetadata)            # @Model for sync outbox tracking
├── ViewModels/                   # @Observable business logic (Account, Transaction, Transfer, Dashboard)
├── Views/
│   ├── ContentView.swift         # Root nav: NavigationSplitView (iPad/macOS) vs TabView (iPhone)
│   ├── Auth/                     # SignInView (Apple Sign-In)
│   ├── Dashboard/                # DashboardView, SankeyDiagramView, SpendingByCategoryView
│   ├── Accounts/                 # AccountList, AccountDetail, AccountForm
│   ├── Transactions/             # TransactionList, TransactionForm, TransactionRow
│   ├── Categories/               # CategoryList, CategoryForm
│   └── Transfers/                # TransferForm
├── Services/
│   ├── Auth/                     # AuthManager (Supabase Auth + Apple Sign-In)
│   ├── Sync/                     # SyncEngine, SupabaseManager, EntityMapper, NetworkMonitor, SyncMetadata
│   ├── CurrencyFormatter.swift
│   └── DefaultCategorySeeder.swift
├── Utilities/                    # Constants, CurrencyExtensions, DateExtensions
└── Resources/                    # Assets.xcassets
Tests/
└── CurrencyTests.swift           # Apple Testing framework
```

## Key Design Decisions

### Currency as Int64 cents
All monetary amounts stored as `Int64` cents (e.g., `$125.50` → `12550`). Avoids floating-point precision issues. JPY and KRW use scale=1 (no decimal places); all others use scale=100.

- `CurrencyFormatter.displayString(cents:currencyCode:)` — format for display
- `CurrencyFormatter.parseToCents(input:currencyCode:)` — parse user input
- `Int64.toCurrencyDecimal(scale:)` / `Decimal.toCents(scale:)` — conversion helpers

### Transfers as paired transactions
Transfers create two linked `Transaction` objects sharing a `transferId` (UUID string). No separate Transfer model. Deleting one side deletes both.

### Balance is computed, never stored
`Account.balanceInCents` sums all related transactions (income positive, expense negative).

### Multi-platform layout
`ContentView` checks `horizontalSizeClass`: compact → iPhone `TabView`; regular → iPad/macOS `NavigationSplitView` with sidebar. Platform-specific code uses `#if os(iOS)` / `#if os(macOS)`.

## Sync Architecture

```
Views (@Query) → SwiftData (local) ←→ SyncEngine ←→ Supabase (remote)
                                          ↑
                                   SupabaseManager + AuthManager
```

- **SwiftData** is the single source of truth for the UI
- **SyncEngine** pushes local changes to Supabase and pulls remote changes into SwiftData
- **Outbox pattern**: `NSManagedObjectContextDidSave` notifications queue changes in `SyncMetadata` model
- **Push**: Debounced 2s after local saves; immediate on connectivity restored
- **Pull**: Full pull on login + Supabase Realtime subscription for live updates
- **Conflict resolution**: Last-write-wins based on `updated_at`
- **Offline-first**: Changes queue locally in `SyncMetadata` while offline, flush when online
- **Migration**: On first Supabase sign-in, all existing local data is bulk-uploaded

### Key Files
- `SupabaseManager.swift` — Singleton `SupabaseClient` initialized from `AppConstants`
- `AuthManager.swift` — Apple Sign-In → Supabase token, session restore, sign out
- `SyncEngine.swift` — Push/pull orchestration, realtime subscription, migration
- `SyncMetadata.swift` — `@Model` tracking pending changes (entityType, entityId, changeType)
- `EntityMapper.swift` — Bidirectional mapping: SwiftData models ↔ `Supabase*Row` Codable DTOs
- `NetworkMonitor.swift` — `NWPathMonitor` wrapper, posts `.connectivityRestored` notification

### Supabase DTOs
Row types use `Supabase` prefix to avoid name collisions with the Supabase SDK:
- `SupabaseAccountRow`, `SupabaseTransactionRow`, `SupabaseCategoryRow`, `SoftDeleteRow`

### Supabase Config
- URL: configured in `AppConstants.supabaseURL`
- Anon Key: configured in `AppConstants.supabaseAnonKey`
- Auth: Apple Sign-In (entitlement: `com.apple.developer.applesignin`)

## Code Conventions

- **MVVM**: Views use `@Query` for data, create ViewModels inline with `ModelContext` for mutations
- **Small files**: 200–400 lines typical, 500 max for complex views (SankeyDiagramView)
- **MARK comments**: `// MARK: - Section Name` to organize view bodies
- **Platform guards**: `#if os(iOS)` for `.insetGrouped`, `.keyboardType`, `.navigationBarTitleDisplayMode`
- **Form style**: `.formStyle(.grouped)` on all forms (cross-platform polished appearance)
- **macOS sheet sizing**: `#if os(macOS) .frame(minWidth: 460, idealWidth: 500, ...)` on modal forms
- **Error handling**: `do/try/catch` at save points, error shown via `.alert` modifier
- **Validation**: `isFormValid` computed property gates the save button with `.disabled(!isFormValid)`
- **No mutation of existing objects outside ViewModels** — all CRUD through ViewModel methods
- **Immutable patterns preferred** — create new values rather than mutating in-place where possible
- **Swift 6 concurrency**: `@MainActor` on observable classes, `Sendable` structs for DTOs

## Adding a New File to the Project

When creating a new Swift file:

1. Place it in the appropriate `Sources/` subdirectory
2. Run `/opt/homebrew/bin/xcodegen generate` to regenerate the project
3. Build both targets to verify

## Data Models

| Model | Key Properties | Relationships |
|-------|---------------|---------------|
| **Account** | name, accountType (String), currency (String), icon (String), createdDate | → [Transaction] (cascade) |
| **Transaction** | amountInCents (Int64), transactionType (String), date, notes, transferId? | → Account?, Category? |
| **Category** | name, icon, colorHex, transactionType (String), isDefault (Bool) | → [Transaction] (nullify) |
| **SyncMetadata** | entityType (String), entityId (String), changeType (String), isSynced, retryCount | — |

## Supported Currencies

USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR, MXN, BRL, KRW, SEK, NOK, DKK — defined in `SupportedCurrency` enum in `FinanceEnums.swift`.

## PostgreSQL Schema (Supabase)

Three tables with Row-Level Security (RLS) — each row has `user_id` for isolation:
- `accounts` — mirrors Account model + `updated_at`, `deleted_at` (soft delete)
- `categories` — mirrors Category model + `updated_at`, `deleted_at`
- `transactions` — mirrors Transaction model + `updated_at`, `deleted_at`, FK to accounts/categories

SQL migration is in the plan file: `~/.claude/plans/sleepy-wondering-karp.md`
