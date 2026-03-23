# FinanceApp

A native personal finance application for **macOS** and **iOS/iPadOS** built with SwiftUI, SwiftData, and Supabase.

## Features

- **Multiple account types** — Checking, Savings, Credit Card, Cash, Investment
- **Income & expense tracking** — Record transactions with amounts, dates, notes, and categories
- **Account transfers** — Move money between accounts with linked paired transactions
- **Category management** — 22 default categories (15 expense, 7 income) with custom icons and colors
- **Cross-device sync** — Real-time sync across all Apple devices via Supabase (PostgreSQL + Realtime)
- **Apple Sign-In** — Secure authentication with row-level security per user
- **Charts & analytics** — Spending by category (pie chart) and money flow (Sankey diagram)
- **Multi-currency support** — 15 currencies (USD, EUR, GBP, JPY, and more)
- **Offline-first** — Works fully offline; syncs automatically when connectivity is restored
- **Adaptive layout** — iPad/macOS use NavigationSplitView with sidebar; iPhone uses a compact TabView

## Screenshots

_Coming soon_

## Requirements

- **macOS 14.0+** / **iOS 17.0+**
- **Xcode 16.0+**
- **Swift 6.0**
- A [Supabase](https://supabase.com) project (free tier works)
- An Apple Developer account (for Sign in with Apple)

## Getting Started

### 1. Clone the repository

```bash
git clone <repo-url>
cd FinanceApp
```

### 2. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Run the SQL migration in the Supabase SQL editor (see `~/.claude/plans/sleepy-wondering-karp.md` for the full schema)
3. Enable Realtime on the `accounts`, `categories`, and `transactions` tables
4. Configure Apple Sign-In in Authentication → Providers
5. Copy your project URL and anon key into `Sources/Utilities/Constants.swift`

### 3. Generate the Xcode project

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate `FinanceApp.xcodeproj` from `project.yml`.

```bash
brew install xcodegen   # if not already installed
xcodegen generate
```

### 4. Open in Xcode

```bash
open FinanceApp.xcodeproj
```

Select the `FinanceApp-iOS` or `FinanceApp-macOS` scheme and run.

### 5. Configure signing

In Xcode, set your Development Team and ensure the "Sign in with Apple" capability is enabled.

## Building from the command line

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# macOS
xcodebuild build -project FinanceApp.xcodeproj \
  -scheme FinanceApp-macOS -configuration Debug \
  CODE_SIGNING_ALLOWED=NO

# iOS Simulator
xcodebuild build -project FinanceApp.xcodeproj \
  -scheme FinanceApp-iOS -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

## Project Structure

```
Sources/
├── FinanceApp.swift              # App entry point, ModelContainer + Supabase setup
├── Models/                       # SwiftData @Model classes
│   ├── Account.swift
│   ├── Transaction.swift
│   ├── Category.swift
│   └── FinanceEnums.swift
├── ViewModels/                   # @Observable business logic
├── Views/
│   ├── ContentView.swift         # Adaptive root navigation
│   ├── Auth/                     # Sign-in screen (Apple Sign-In)
│   ├── Dashboard/                # Dashboard, Sankey diagram, spending chart
│   ├── Accounts/                 # Account list, detail, form
│   ├── Transactions/             # Transaction list, form, row
│   ├── Categories/               # Category list, form
│   └── Transfers/                # Transfer form
├── Services/
│   ├── Auth/                     # AuthManager (Supabase + Apple Sign-In)
│   ├── Sync/                     # SyncEngine, SupabaseManager, EntityMapper, NetworkMonitor
│   ├── CurrencyFormatter.swift
│   └── DefaultCategorySeeder.swift
└── Utilities/                    # Constants, extensions
Tests/
└── CurrencyTests.swift
```

## Architecture

- **MVVM** — Views use `@Query` for reactive data; ViewModels handle mutations via `ModelContext`
- **SwiftData (local) + Supabase (remote)** — SwiftData is the UI's single source of truth; SyncEngine pushes/pulls to Supabase
- **Offline-first** — Changes queue in `SyncMetadata` while offline, sync on connectivity restored
- **Last-write-wins** — Conflict resolution based on `updated_at` timestamps
- **Currency as Int64 cents** — Avoids floating-point precision issues (e.g. `$125.50` = `12550`)
- **Transfers as paired transactions** — Two linked `Transaction` objects sharing a `transferId`
- **Computed balances** — `Account.balanceInCents` is always derived from its transactions, never stored

## License

Private — All rights reserved.
