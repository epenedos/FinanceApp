import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        #if os(iOS)
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
        #else
        NavigationSplitView {
            SidebarView()
        } detail: {
            DashboardView()
        }
        .frame(minWidth: 700, minHeight: 500)
        #endif
    }
}

#if os(macOS)
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
        }
        .navigationTitle("Finance")
        .listStyle(.sidebar)
    }
}
#endif
