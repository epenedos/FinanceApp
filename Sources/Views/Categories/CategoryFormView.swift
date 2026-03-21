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
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                        spacing: 12
                    ) {
                        ForEach(iconOptions, id: \.self) { iconName in
                            Button {
                                icon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(
                                        icon == iconName
                                            ? Color(hex: colorHex).opacity(0.2)
                                            : Color.secondary.opacity(0.12)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay {
                                        if icon == iconName {
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(Color(hex: colorHex), lineWidth: 2)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                        spacing: 12
                    ) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex).gradient)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay {
                                        if colorHex == hex {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 2)
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
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color(hex: colorHex).gradient)
                            .clipShape(Circle())

                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)

                        Spacer()

                        Text(transactionType.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .formStyle(.grouped)
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
                if let category {
                    name = category.name
                    icon = category.icon
                    colorHex = category.colorHex
                    transactionType = category.transactionTypeEnum
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 580, idealHeight: 640)
        #endif
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
                try modelContext.save()
                SyncNotification.post(entityType: .category, entityId: category.id, changeType: .update)
            } else {
                let newCategory = Category(
                    name: trimmedName,
                    icon: icon,
                    colorHex: colorHex,
                    transactionType: transactionType
                )
                modelContext.insert(newCategory)
                try modelContext.save()
                SyncNotification.post(entityType: .category, entityId: newCategory.id, changeType: .insert)
            }
            dismiss()
        } catch {
            errorMessage = "Failed to save category: \(error.localizedDescription)"
            showingError = true
        }
    }
}
