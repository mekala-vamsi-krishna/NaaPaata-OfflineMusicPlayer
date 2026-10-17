//
//  AppUpdateUseCase.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import Foundation

final class CheckForAppUpdateUseCase: CheckForAppUpdateUseCaseProtocol {

    private let repository: VersionHistoryRepositoryProtocol
    private let currentVersionProvider: CurrentVersionProviderProtocol

    init(
        repository: VersionHistoryRepositoryProtocol,
        currentVersionProvider: CurrentVersionProviderProtocol
    ) {
        self.repository = repository
        self.currentVersionProvider = currentVersionProvider
    }

    func execute() async -> AppUpdateState {
        let currentVersion = currentVersionProvider.currentVersion

        do {
            let versions = try await repository.fetchVersionHistory()

            guard let latest = latestVersion(in: versions) else {
                return .upToDate
            }

            return isVersion(latest.version, newerThan: currentVersion)
                ? .updateAvailable(latest)
                : .upToDate
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func latestVersion(in versions: [VersionInfo]) -> VersionInfo? {
        versions.max { a, b in
            a.version.compare(b.version, options: .numeric) == .orderedAscending
        }
    }

    private func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        candidate.compare(current, options: .numeric) == .orderedDescending
    }
}
