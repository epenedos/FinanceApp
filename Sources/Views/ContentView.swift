import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .regular {
            sidebarLayout
        } else {
            compactLayout
        }
        #else
        sidebarLayout
        #endif
    }

    // MARK: - Sidebar Layout (macOS + iPad)

    private var sidebarLayout: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DashboardView()
        }
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 500)
        #endif
    }

    // MARK: - Compact Layout (iPhone)

    #if os(iOS)
    private var compactLayout: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "chart.pie") }

            NavigationStack {
                AccountListView()
            }
            .tabItem { Label("Accounts", systemImage: "building.columns") }

            NavigationStack {
                TransactionListView()
            }
            .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                CategoryListView()
            }
            .tabItem { Label("Categories", systemImage: "tag") }
        }
    }
    #endif
}

// MARK: - Sidebar (shared between macOS and iPadOS)

struct SidebarView: View {
    var body: some View {
        List {
            NavigationLink {
                DashboardView()
            } label: {
                Label("Dashboard", systemImage: "chart.pie")
            }

            NavigationLink {
                AccountListView()
            } label: {
                Label("Accounts", systemImage: "building.columns")
            }

            NavigationLink {
                TransactionListView()
            } label: {
                Label("Transactions", systemImage: "list.bullet.rectangle")
            }

            NavigationLink {
                CategoryListView()
            } label: {
                Label("Categories", systemImage: "tag")
            }

            Section("Charts") {
                NavigationLink {
                    SankeyDiagramView()
                } label: {
                    Label("Money Flow", systemImage: "chart.bar.xaxis")
                }

                NavigationLink {
                    SpendingByCategoryView()
                } label: {
                    Label("Spending", systemImage: "chart.pie")
                }
            }
        }
        .navigationTitle("Finance")
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }
}
