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
                    Text("No expense categories")
                        .foregroundStyle(.secondary)
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
                    Text("No income categories")
                        .foregroundStyle(.secondary)
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
}

struct CategoryRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(category.color)
                .clipShape(Circle())

            Text(category.name)
                .font(.body)

            Spacer()

            if category.isDefault {
                Text("Default")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
