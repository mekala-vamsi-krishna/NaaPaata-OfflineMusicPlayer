//
//  SearchScope.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/14/26.
//

import Foundation

enum SearchScope: String, CaseIterable, Identifiable {
    case songs
    case albums
    case playlists

    var id: String { rawValue }

    var title: String {
        switch self {
        case .songs:     return "Songs"
        case .albums:    return "Albums"
        case .playlists: return "Playlists"
        }
    }

    /// Prompt shown inside the search field.
    var placeholder: String {
        switch self {
        case .songs:     return "Search songs"
        case .albums:    return "Search albums"
        case .playlists: return "Search playlists"
        }
    }
}
