import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.signOutAction) private var signOutAction
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var showSignOutConfirmation = false

    var body: some View {
        Group {
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
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await signOutAction?() }
            }
        }
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
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button(role: .destructive) {
                                    showSignOutConfirmation = true
                                } label: {
                                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            } label: {
                                Image(systemName: "person.circle")
                            }
                        }
                    }
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
    @Environment(\.signOutAction) private var signOutAction

    @State private var showSignOutConfirmation = false

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

            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Finance")
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await signOutAction?() }
            }
        }
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }
}
