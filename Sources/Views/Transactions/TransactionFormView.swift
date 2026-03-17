import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]

    let transaction: Transaction?
    var preselectedAccount: Account?

    @State private var transactionType: TransactionType = .expense
    @State private var amountText: String = ""
    @State private var selectedAccount: Account?
    @State private var selectedCategory: Category?
    @State private var date: Date = .now
    @State private var notes: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var isEditing: Bool { transaction != nil }

    private var filteredCategories: [Category] {
        categories.filter { $0.transactionType == transactionType.rawValue && $0.name != "Transfer" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Transaction Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: transactionType) { _, _ in
                        selectedCategory = nil
                    }
                }

                Section("Details") {
                    TextField("Amount", text: $amountText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif

                    Picker("Account", selection: $selectedAccount) {
                        Text("Select Account").tag(nil as Account?)
                        ForEach(accounts) { account in
                            Text(account.name).tag(account as Account?)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    if filteredCategories.isEmpty {
                        Text("No categories available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag(nil as Category?)
                            ForEach(filteredCategories) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(category as Category?)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear { populateFields() }
        }
    }

    private var isFormValid: Bool {
        guard selectedAccount != nil else { return false }
        guard selectedCategory != nil else { return false }
        guard let cents = parsedAmountInCents, cents > 0 else { return false }
        return true
    }

    private var parsedAmountInCents: Int64? {
        let currencyCode = selectedAccount?.currency ?? AppConstants.defaultCurrencyCode
        return CurrencyFormatter.parseToCents(input: amountText, currencyCode: currencyCode)
    }

    private func populateFields() {
        if let transaction {
            transactionType = transaction.transactionTypeEnum
            let currency = transaction.account?.currencyEnum ?? .usd
            let decimal = transaction.amountInCents.toCurrencyDecimal(scale: currency.minorUnitScale)
            amountText = "\(decimal)"
            selectedAccount = transaction.account
            selectedCategory = transaction.category
            date = transaction.date
            notes = transaction.notes
        } else if let preselectedAccount {
            selectedAccount = preselectedAccount
        }
    }

    private func save() {
        guard let account = selectedAccount,
              let category = selectedCategory,
              let cents = parsedAmountInCents, cents > 0 else { return }

        do {
            let viewModel = TransactionViewModel(modelContext: modelContext)
            if let transaction {
                try viewModel.updateTransaction(
                    transaction,
                    amountInCents: cents,
                    transactionType: transactionType,
                    date: date,
                    notes: notes,
                    account: account,
                    category: category
                )
            } else {
                try viewModel.createTransaction(
                    amountInCents: cents,
                    transactionType: transactionType,
                    date: date,
                    notes: notes,
                    account: account,
                    category: category
                )
            }
            dismiss()
        } catch {
            errorMessage = "Failed to save transaction: \(error.localizedDescription)"
            showingError = true
        }
    }
}
