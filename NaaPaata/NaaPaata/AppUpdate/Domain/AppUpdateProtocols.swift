//
//  AppUpdateProtocols.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import Foundation

// MARK: - Repository

protocol VersionHistoryRepositoryProtocol: Sendable {
    func fetchVersionHistory() async throws -> [VersionInfo]
}

// MARK: - Data Sources

protocol VersionHistoryRemoteDataSourceProtocol: Sendable {
    func fetch() async throws -> [VersionInfo]
}

protocol VersionHistoryLocalDataSourceProtocol: Sendable {
    func load() throws -> [VersionInfo]
}

protocol VersionHistoryCacheProtocol: Sendable {
    func save(_ versions: [VersionInfo]) throws
    func load() throws -> [VersionInfo]
}

// MARK: - Use Case

protocol CheckForAppUpdateUseCaseProtocol: Sendable {
    func execute() async -> AppUpdateState
}

// MARK: - Supporting Services

protocol CurrentVersionProviderProtocol: Sendable {
    var currentVersion: String { get }
}

protocol DismissedVersionsStoreProtocol: Sendable {
    func isDismissed(_ version: String) -> Bool
    func dismiss(_ version: String)
}

protocol AppStoreOpenerProtocol: Sendable {
    func openAppStore()
}

protocol AppUpdateCheckGateProtocol: Sendable {
    var shouldCheck: Bool { get }
    func markChecked()
}
