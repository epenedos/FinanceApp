import Foundation
import Network
import Observation

// MARK: - Network Connectivity Monitor

/// Wraps NWPathMonitor to provide an observable connectivity state.
/// Used by SyncEngine to determine when to push/pull changes.
@Observable
@MainActor
final class NetworkMonitor: Sendable {

    // MARK: - Properties

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.financeapp.networkmonitor")

    // MARK: - Types

    enum ConnectionType: String, Sendable {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    // MARK: - Lifecycle

    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            let wifi = path.usesInterfaceType(.wifi)
            let cellular = path.usesInterfaceType(.cellular)
            let ethernet = path.usesInterfaceType(.wiredEthernet)

            Task { @MainActor in
                self?.applyConnectionStatus(
                    satisfied: satisfied,
                    wifi: wifi,
                    cellular: cellular,
                    ethernet: ethernet
                )
            }
        }
        monitor.start(queue: queue)
    }

    private func applyConnectionStatus(
        satisfied: Bool,
        wifi: Bool,
        cellular: Bool,
        ethernet: Bool
    ) {
        let wasConnected = isConnected
        isConnected = satisfied

        if wifi {
            connectionType = .wifi
        } else if cellular {
            connectionType = .cellular
        } else if ethernet {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }

        if !wasConnected && isConnected {
            NotificationCenter.default.post(
                name: .connectivityRestored,
                object: nil
            )
        }
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let connectivityRestored = Notification.Name("connectivityRestored")
}
