//
//  AppUpdateServices.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import Foundation
import UIKit

// MARK: - Current Version

final class BundleCurrentVersionProvider: CurrentVersionProviderProtocol {
    var currentVersion: String {
        #if DEBUG
        if AppUpdateConfiguration.forceShowUpdate {
            return AppUpdateConfiguration.fakeCurrentVersion
        }
        #endif
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
}

// MARK: - Dismissed Versions

final class UserDefaultsDismissedVersionsStore: DismissedVersionsStoreProtocol, @unchecked Sendable {

    private let key = "dismissedAppUpdateVersions"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isDismissed(_ version: String) -> Bool {
        #if DEBUG
        if AppUpdateConfiguration.forceShowUpdate { return false }
        #endif
        return (defaults.stringArray(forKey: key) ?? []).contains(version)
    }

    func dismiss(_ version: String) {
        var list = defaults.stringArray(forKey: key) ?? []
        guard !list.contains(version) else { return }
        list.append(version)
        defaults.set(list, forKey: key)
    }
}

// MARK: - App Store Opener

final class DefaultAppStoreOpener: AppStoreOpenerProtocol {

    private let appStoreID: String

    init(appStoreID: String) {
        self.appStoreID = appStoreID
    }

    func openAppStore() {
        let region = Locale.current.region?.identifier.lowercased() ?? "us"
        let urlString = "https://apps.apple.com/\(region)/app/id\(appStoreID)"
        guard let url = URL(string: urlString) else { return }

        Task { @MainActor in
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Check Gate

/// Prevents hitting the remote endpoint on every launch.
/// Default: one check per 24 hours.
final class AppUpdateCheckGate: AppUpdateCheckGateProtocol, @unchecked Sendable {

    private let key = "lastAppUpdateCheckDate"
    private let minimumInterval: TimeInterval
    private let defaults: UserDefaults

    init(
        minimumInterval: TimeInterval = 60 * 60 * 24,
        defaults: UserDefaults = .standard
    ) {
        self.minimumInterval = minimumInterval
        self.defaults = defaults
    }

    var shouldCheck: Bool {
        #if DEBUG
        if AppUpdateConfiguration.forceShowUpdate { return true }
        #endif
        guard let last = defaults.object(forKey: key) as? Date else { return true }
        return Date().timeIntervalSince(last) >= minimumInterval
    }

    func markChecked() {
        defaults.set(Date(), forKey: key)
    }
}
