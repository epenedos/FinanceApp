import SwiftUI
import SwiftData

struct AccountFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account?

    @State private var name: String = ""
    @State private var accountType: AccountType = .checking
    @State private var currency: SupportedCurrency = .usd
    @State private var icon: String = "building.columns"
    @State private var showingError = false
    @State private var errorMessage = ""

    private var isEditing: Bool { account != nil }

    private let iconOptions = [
        "building.columns", "banknote", "creditcard", "dollarsign.circle",
        "chart.line.uptrend.xyaxis", "house", "briefcase", "cart",
        "car", "airplane", "gift", "heart",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $name)
                        .font(.body)

                    Picker("Account Type", selection: $accountType) {
                        ForEach(AccountType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Currency", selection: $currency) {
                        ForEach(SupportedCurrency.allCases) { curr in
                            Text(curr.displayName).tag(curr)
                        }
                    }
                }

                Section("Icon") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                        spacing: 12
                    ) {
                        ForEach(iconOptions, id: \.self) { iconName in
                            Button {
                                icon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        icon == iconName
                                            ? Color.accentColor.opacity(0.2)
                                            : Color.secondary.opacity(0.12)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay {
                                        if icon == iconName {
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(Color.accentColor, lineWidth: 2)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preview") {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.accentColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "Account Name" : name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(name.isEmpty ? .secondary : .primary)
                            Text(accountType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(currency.symbol)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Account" : "New Account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let account {
                    name = account.name
                    accountType = account.accountTypeEnum
                    currency = account.currencyEnum
                    icon = account.icon
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 480, idealHeight: 540)
        #endif
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        do {
            let viewModel = AccountViewModel(modelContext: modelContext)
            if let account {
                try viewModel.updateAccount(
                    account,
                    name: trimmedName,
                    accountType: accountType,
                    currency: currency,
                    icon: icon
                )
            } else {
                try viewModel.createAccount(
                    name: trimmedName,
                    accountType: accountType,
                    currency: currency,
                    icon: icon
                )
            }
            dismiss()
        } catch {
            errorMessage = "Failed to save account: \(error.localizedDescription)"
            showingError = true
        }
    }
}
