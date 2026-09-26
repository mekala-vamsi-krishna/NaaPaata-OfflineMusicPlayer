//
//  SidebarItem.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import Foundation

enum SidebarItem: String, CaseIterable, Identifiable {
    case search
    case songs
    case favourites
    case albums
    case artists
    case genres
    case playlists

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search:     return "Search"
        case .songs:      return "Songs"
        case .favourites: return "Favourites"
        case .albums:     return "Albums"
        case .artists:    return "Artists"
        case .genres:     return "Genres"
        case .playlists:  return "Playlists"
        }
    }

    var systemImage: String {
        switch self {
        case .search:     return "magnifyingglass"
        case .songs:      return "music.note"
        case .favourites: return "heart"
        case .albums:     return "square.stack"
        case .artists:    return "music.mic"
        case .genres:     return "guitars"
        case .playlists:  return "music.note.list"
        }
    }
}
