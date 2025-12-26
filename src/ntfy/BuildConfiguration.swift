//
//  BuildConfiguration.swift
//  ntfy
//
//  Provides build configuration detection for separating Debug/Release data stores
//

import Foundation

enum BuildConfiguration {
    case debug
    case release

    static var current: BuildConfiguration {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }

    /// Keychain service identifier
    var keychainService: String {
        switch self {
        case .debug: return "me.mahardi.ntfy.debug"
        case .release: return "me.mahardi.ntfy"
        }
    }

    /// App group identifier for shared data
    var appGroup: String {
        switch self {
        case .debug: return "group.me.mahardi.ntfy.debug"
        case .release: return "group.me.mahardi.ntfy"
        }
    }

    /// SwiftData store name (creates separate database files)
    var swiftDataStoreName: String {
        switch self {
        case .debug: return "ntfy-debug"
        case .release: return "default"  // Keep existing name for release data
        }
    }

    /// UserDefaults key prefix to avoid collisions
    var userDefaultsPrefix: String {
        switch self {
        case .debug: return "debug."
        case .release: return ""
        }
    }
    
    var menubarIcon: String {
        switch self {
        case .debug:
            return "bell.slash.fill"
        case .release:
            return "bell.fill"
        }
    }
    
    var menubarIconWithNotification: String {
        switch self {
        case .debug:
            return "bell.badge.slash.fill"
        case .release:
            return "bell.badge.fill"
        }
    }
}
