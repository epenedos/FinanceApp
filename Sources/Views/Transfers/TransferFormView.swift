import SwiftUI
import SwiftData

struct TransferFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.name) private var accounts: [Account]

    var preselectedSourceAccount: Account?

    @State private var sourceAccount: Account?
    @State private var destinationAccount: Account?
    @State private var amountText: String = ""
    @State private var date: Date = .now
    @State private var notes: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var availableDestinations: [Account] {
        accounts.filter { $0.id != sourceAccount?.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Picker("Source Account", selection: $sourceAccount) {
                        Text("Select Account").tag(nil as Account?)
                        ForEach(accounts) { account in
                            HStack {
                                Text(account.name)
                                Spacer()
                                Text(CurrencyFormatter.displayString(
                                    cents: account.balanceInCents,
                                    currencyCode: account.currency
                                ))
                                .foregroundStyle(.secondary)
                            }
                            .tag(account as Account?)
                        }
                    }
                }

                Section("To") {
                    Picker("Destination Account", selection: $destinationAccount) {
                        Text("Select Account").tag(nil as Account?)
                        ForEach(availableDestinations) { account in
                            Text(account.name).tag(account as Account?)
                        }
                    }
                }

                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif

                    if let source = sourceAccount, let dest = destinationAccount,
                       source.currency != dest.currency {
                        Label(
                            "Accounts use different currencies. The amount will be applied as-is to both.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Transfer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") { executeTransfer() }
                        .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let preselectedSourceAccount {
                    sourceAccount = preselectedSourceAccount
                }
            }
        }
    }

    private var isFormValid: Bool {
        guard sourceAccount != nil else { return false }
        guard destinationAccount != nil else { return false }
        guard let cents = parsedAmountInCents, cents > 0 else { return false }
        return true
    }

    private var parsedAmountInCents: Int64? {
        let currencyCode = sourceAccount?.currency ?? AppConstants.defaultCurrencyCode
        return CurrencyFormatter.parseToCents(input: amountText, currencyCode: currencyCode)
    }

    private func executeTransfer() {
        guard let source = sourceAccount,
              let dest = destinationAccount,
              let cents = parsedAmountInCents, cents > 0 else { return }

        do {
            let viewModel = TransferViewModel(modelContext: modelContext)
            try viewModel.executeTransfer(
                from: source,
                to: dest,
                amountInCents: cents,
                date: date,
                notes: notes
            )
            dismiss()
        } catch {
            errorMessage = "Failed to execute transfer: \(error.localizedDescription)"
            showingError = true
        }
    }
}
