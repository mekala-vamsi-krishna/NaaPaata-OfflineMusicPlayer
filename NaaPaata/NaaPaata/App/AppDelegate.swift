//
//  AppDelegate.swift
//  NaaPaata
//

import Foundation
import SwiftUI
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {

    static weak var libraryViewModel: MusicLibraryViewModel?
    static weak var folderService: DocumentFolderService?

    static var modelContainer: ModelContainer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }
}
