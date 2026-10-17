//
//  AppUpdateViewModel.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import Foundation
import SwiftUI

@MainActor
final class AppUpdateViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var state: AppUpdateState = .idle
    @Published var isSheetPresented = false

    // MARK: - Dependencies

    private let useCase: CheckForAppUpdateUseCaseProtocol
    private let repository: VersionHistoryRepositoryProtocol
    private let dismissedStore: DismissedVersionsStoreProtocol
    private let appStoreOpener: AppStoreOpenerProtocol
    private let checkGate: AppUpdateCheckGateProtocol

    // MARK: - Init

    init(
        useCase: CheckForAppUpdateUseCaseProtocol,
        repository: VersionHistoryRepositoryProtocol,
        dismissedStore: DismissedVersionsStoreProtocol,
        appStoreOpener: AppStoreOpenerProtocol,
        checkGate: AppUpdateCheckGateProtocol
    ) {
        self.useCase = useCase
        self.repository = repository

        self.dismissedStore = dismissedStore
        self.appStoreOpener = appStoreOpener
        self.checkGate = checkGate
    }

    // MARK: - Public API

    /// Respects the cooldown. Call this on app launch.
    func checkForUpdateIfNeeded() async {
        guard checkGate.shouldCheck else { return }
        await checkForUpdate()
    }

    /// Ignores the cooldown. Use for a manual "Check for updates" button.
    func checkForUpdate() async {
        state = .checking
        checkGate.markChecked()

        let result = await useCase.execute()
        state = result

        if case .updateAvailable(let info) = result,
           !dismissedStore.isDismissed(info.version) {
            isSheetPresented = true
        }
    }

    func openAppStore() {
        appStoreOpener.openAppStore()
        // Don't mark as dismissed — the user may come back without updating.
        isSheetPresented = false
    }

    func dismiss() {
        if case .updateAvailable(let info) = state {
            dismissedStore.dismiss(info.version)
        }
        isSheetPresented = false
    }
    
    func loadVersionHistory() async -> Result<[VersionInfo], Error> {
        do {
            let versions = try await repository.fetchVersionHistory()
            return .success(versions)
        } catch {
            return .failure(error)
        }
    }
}
