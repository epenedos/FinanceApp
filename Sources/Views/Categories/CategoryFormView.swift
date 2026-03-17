import SwiftUI
import SwiftData

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: Category?

    @State private var name: String = ""
    @State private var icon: String = "tag"
    @State private var colorHex: String = "#007AFF"
    @State private var transactionType: TransactionType = .expense
    @State private var showingError = false
    @State private var errorMessage = ""

    private var isEditing: Bool { category != nil }

    private let iconOptions = [
        "tag", "cart", "fork.knife", "car", "house", "bolt",
        "heart", "film", "bag", "book", "person", "airplane",
        "gift", "shield", "repeat", "briefcase", "laptopcomputer",
        "chart.line.uptrend.xyaxis", "banknote", "arrow.uturn.backward",
        "ellipsis.circle", "gamecontroller", "paintbrush", "wrench",
    ]

    private let colorOptions = [
        "#FF6B6B", "#FF8E53", "#FFC107", "#4CAF50", "#2196F3",
        "#E91E63", "#9C27B0", "#673AB7", "#3F51B5", "#00BCD4",
        "#009688", "#795548", "#607D8B", "#FF5722", "#9E9E9E",
        "#8BC34A", "#CDDC39", "#FFEB3B",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Category Name", text: $name)

                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { iconName in
                            Button {
                                icon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(icon == iconName ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: colorHex))
                            .clipShape(Circle())

                        Text(name.isEmpty ? "Category Name" : name)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let category {
                    name = category.name
                    icon = category.icon
                    colorHex = category.colorHex
                    transactionType = category.transactionTypeEnum
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        do {
            if let category {
                category.name = trimmedName
                category.icon = icon
                category.colorHex = colorHex
                category.transactionType = transactionType.rawValue
            } else {
                let newCategory = Category(
                    name: trimmedName,
                    icon: icon,
                    colorHex: colorHex,
                    transactionType: transactionType
                )
                modelContext.insert(newCategory)
            }
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save category: \(error.localizedDescription)"
            showingError = true
        }
    }
}
