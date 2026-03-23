import SwiftUI

struct SignOutActionKey: EnvironmentKey {
    static let defaultValue: (@Sendable () async -> Void)? = nil
}

extension EnvironmentValues {
    var signOutAction: (@Sendable () async -> Void)? {
        get { self[SignOutActionKey.self] }
        set { self[SignOutActionKey.self] = newValue }
    }
}
