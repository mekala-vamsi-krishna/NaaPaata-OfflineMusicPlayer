//
//  AppUpdateRepository.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import Foundation

final class AppUpdateRepository: VersionHistoryRepositoryProtocol {

    private let remote: VersionHistoryRemoteDataSourceProtocol
    private let local: VersionHistoryLocalDataSourceProtocol
    private let cache: VersionHistoryCacheProtocol

    init(
        remote: VersionHistoryRemoteDataSourceProtocol,
        local: VersionHistoryLocalDataSourceProtocol,
        cache: VersionHistoryCacheProtocol
    ) {
        self.remote = remote
        self.local = local
        self.cache = cache
    }

    /// Cache-first strategy:
    /// 1. Remote is the source of truth — always try first.
    /// 2. On success, refresh the disk cache.
    /// 3. On failure, read the disk cache.
    /// 4. If the cache is empty, use the bundled JSON.
    func fetchVersionHistory() async throws -> [VersionInfo] {
        do {
            let versions = try await remote.fetch()
            try? cache.save(versions)
            return versions
        } catch {
            if let cached = try? cache.load() {
                return cached
            }
            return try local.load()
        }
    }
}
