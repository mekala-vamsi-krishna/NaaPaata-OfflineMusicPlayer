//
//  AppRouter.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import SwiftUI
import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push<V: Hashable>(_ value: V) {
        path.append(value)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
