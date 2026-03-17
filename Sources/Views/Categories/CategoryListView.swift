import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingAddForm = false
    @State private var categoryToEdit: Category?

    private var expenseCategories: [Category] {
        categories.filter { $0.transactionType == TransactionType.expense.rawValue }
    }

    private var incomeCategories: [Category] {
        categories.filter { $0.transactionType == TransactionType.income.rawValue }
    }

    var body: some View {
        List {
            Section("Expense Categories") {
                if expenseCategories.isEmpty {
                    emptyRow(message: "No expense categories")
                } else {
                    ForEach(expenseCategories) { category in
                        CategoryRow(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                categoryToEdit = category
                            }
                    }
                }
            }

            Section("Income Categories") {
                if incomeCategories.isEmpty {
                    emptyRow(message: "No income categories")
                } else {
                    ForEach(incomeCategories) { category in
                        CategoryRow(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                categoryToEdit = category
                            }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddForm = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddForm) {
            CategoryFormView(category: nil)
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryFormView(category: category)
        }
    }

    private func emptyRow(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
    }
}

struct CategoryRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(category.color.gradient)
                .clipShape(Circle())

            Text(category.name)
                .font(.body)

            Spacer(minLength: 4)

            if category.isDefault {
                Text("Default")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
