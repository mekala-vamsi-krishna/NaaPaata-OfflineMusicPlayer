//
//  AppRouter.swift
//  NaaPaata
//

import SwiftUI

/// Owns the navigation path for one `NavigationStack`. Create one per
/// tab so each tab keeps its own history.
@MainActor
final class AppRouter: ObservableObject {

    @Published var path = NavigationPath()

    func push<V: Hashable>(_ value: V) {
        path.append(value)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
