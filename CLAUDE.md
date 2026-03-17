# FinanceApp

Personal finance app for macOS 14+ and iOS 17+. Manages multiple accounts, transfers, income/expense tracking with categories, and syncs via iCloud/CloudKit.

## Tech Stack

- **Swift 6.0** / **SwiftUI** / **SwiftData** (persistence) / **CloudKit** (iCloud sync)
- **XcodeGen** (`project.yml` generates `FinanceApp.xcodeproj`)
- **Architecture**: MVVM — Views own `@State`, ViewModels hold business logic, Models are `@Model` classes

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

After modifying `project.yml`, regenerate the Xcode project: `xcodegen generate`

## Project Structure

```
Sources/
├── FinanceApp.swift              # @main, ModelContainer + CloudKit config
├── Models/                       # @Model classes (Account, Transaction, Category, FinanceEnums)
├── ViewModels/                   # @Observable business logic (Account, Transaction, Transfer, Dashboard)
├── Views/
│   ├── ContentView.swift         # Root nav: NavigationSplitView (iPad/macOS) vs TabView (iPhone)
│   ├── Dashboard/                # DashboardView, SankeyDiagramView, SpendingByCategoryView
│   ├── Accounts/                 # AccountList, AccountDetail, AccountForm
│   ├── Transactions/             # TransactionList, TransactionForm, TransactionRow
│   ├── Categories/               # CategoryList, CategoryForm
│   └── Transfers/                # TransferForm
├── Services/                     # CurrencyFormatter, DefaultCategorySeeder
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

### CloudKit constraints
All `@Model` properties have defaults, all relationships are optional, enums stored as `String` raw values, no `#Unique` constraints. Sync mode is `.automatic` (reads container ID from entitlements).

### Multi-platform layout
`ContentView` checks `horizontalSizeClass`: compact → iPhone `TabView`; regular → iPad/macOS `NavigationSplitView` with sidebar. Platform-specific code uses `#if os(iOS)` / `#if os(macOS)`.

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

## Adding a New File to the Project

When creating a new Swift file:

1. Place it in the appropriate `Sources/` subdirectory
2. Add to `project.yml` under both iOS and macOS target sources (or regenerate)
3. **OR** manually add to `project.pbxproj`: PBXFileReference + PBXGroup + PBXBuildFile (×2, one per target) + PBXSourcesBuildPhase (×2)
4. Build both targets to verify

## Data Models

| Model | Key Properties | Relationships |
|-------|---------------|---------------|
| **Account** | name, accountType (String), currency (String), icon (String), createdDate | → [Transaction] (cascade) |
| **Transaction** | amountInCents (Int64), transactionType (String), date, notes, transferId? | → Account?, Category? |
| **Category** | name, icon, colorHex, transactionType (String), isDefault (Bool) | → [Transaction] (nullify) |

## Supported Currencies

USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR, MXN, BRL, KRW, SEK, NOK, DKK — defined in `SupportedCurrency` enum in `FinanceEnums.swift`.

## iCloud Sync

- Container: `iCloud.com.eduardopenedos.FinanceApp`
- Bundle ID: `com.eduardopenedos.FinanceApp`
- Development Team: `MV45ATG98E`
- Entitlements: CloudKit, ubiquity KVStore, `aps-environment: development`
- Remote changes merged via `NSPersistentStoreRemoteChange` + `NSPersistentCloudKitContainer.eventChangedNotification`
