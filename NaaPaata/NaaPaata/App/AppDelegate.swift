//
//  AppDelegate.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/11/26.
//
import Foundation
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    static var dataService: DataServiceProtocol?
    static var songLibraryService: SongLibraryService?
    static var songsViewModel: SongsViewModel?
    static var albumsViewModel: AlbumsViewModel?
    static var playlistsViewModel: PlaylistsViewModel?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool { true }
}
