# FinanceApp

A native personal finance application for **macOS** and **iOS/iPadOS** built with SwiftUI, SwiftData, and CloudKit.

## Features

- **Multiple account types** — Checking, Savings, Credit Card, Cash, Investment
- **Income & expense tracking** — Record transactions with amounts, dates, notes, and categories
- **Account transfers** — Move money between accounts with linked paired transactions
- **Category management** — 22 default categories (15 expense, 7 income) with custom icons and colors
- **iCloud sync** — Real-time sync across all devices via CloudKit
- **Charts & analytics** — Spending by category (pie chart) and money flow (Sankey diagram)
- **Multi-currency support** — 15 currencies (USD, EUR, GBP, JPY, and more)
- **Adaptive layout** — iPad/macOS use NavigationSplitView with sidebar; iPhone uses a compact TabView

## Screenshots

_Coming soon_

## Requirements

- **macOS 14.0+** / **iOS 17.0+**
- **Xcode 16.0+**
- **Swift 6.0**
- An Apple Developer account (for iCloud/CloudKit sync)

## Getting Started

### 1. Clone the repository

```bash
git clone <repo-url>
cd FinanceApp
```

### 2. Generate the Xcode project

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate `FinanceApp.xcodeproj` from `project.yml`.

```bash
brew install xcodegen   # if not already installed
xcodegen generate
```

### 3. Open in Xcode

```bash
open FinanceApp.xcodeproj
```

Select the `FinanceApp-iOS` or `FinanceApp-macOS` scheme and run.

### 4. iCloud setup

To enable CloudKit sync, configure your signing team in Xcode and ensure the iCloud capability is enabled with the container `iCloud.com.eduardopenedos.FinanceApp`.

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
├── FinanceApp.swift              # App entry point, ModelContainer + CloudKit
├── Models/                       # SwiftData @Model classes
│   ├── Account.swift
│   ├── Transaction.swift
│   ├── Category.swift
│   └── FinanceEnums.swift
├── ViewModels/                   # @Observable business logic
├── Views/
│   ├── ContentView.swift         # Adaptive root navigation
│   ├── Dashboard/                # Dashboard, Sankey diagram, spending chart
│   ├── Accounts/                 # Account list, detail, form
│   ├── Transactions/             # Transaction list, form, row
│   ├── Categories/               # Category list, form
│   └── Transfers/                # Transfer form
├── Services/                     # CurrencyFormatter, DefaultCategorySeeder
└── Utilities/                    # Constants, extensions
Tests/
└── CurrencyTests.swift
```

## Architecture

- **MVVM** — Views use `@Query` for reactive data; ViewModels handle mutations via `ModelContext`
- **SwiftData + CloudKit** — All persistence through `@Model` classes with `.automatic` CloudKit sync
- **Currency as Int64 cents** — Avoids floating-point precision issues (e.g. `$125.50` = `12550`)
- **Transfers as paired transactions** — Two linked `Transaction` objects sharing a `transferId`
- **Computed balances** — `Account.balanceInCents` is always derived from its transactions, never stored

## License

Private — All rights reserved.
