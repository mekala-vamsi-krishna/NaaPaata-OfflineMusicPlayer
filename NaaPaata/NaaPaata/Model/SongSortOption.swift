//
//  SongSortOption.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation

enum SongSortOption: String, CaseIterable, Identifiable {
    case titleAscending
    case titleDescending
    case artistAscending
    case albumAscending
    case durationAscending
    case durationDescending
    case dateAddedNewest
    case dateAddedOldest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAscending:     return "Title (A–Z)"
        case .titleDescending:    return "Title (Z–A)"
        case .artistAscending:    return "Artist (A–Z)"
        case .albumAscending:     return "Album (A–Z)"
        case .durationAscending:  return "Duration (Shortest)"
        case .durationDescending: return "Duration (Longest)"
        case .dateAddedNewest:    return "Date Added (Newest)"
        case .dateAddedOldest:    return "Date Added (Oldest)"
        }
    }

    func areInIncreasingOrder(_ lhs: Song, _ rhs: Song) -> Bool {
        switch self {
        case .titleAscending:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        case .titleDescending:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedDescending
        case .artistAscending:
            return lhs.artist.localizedStandardCompare(rhs.artist) == .orderedAscending
        case .albumAscending:
            return lhs.album.localizedStandardCompare(rhs.album) == .orderedAscending
        case .durationAscending:
            return (lhs.duration ?? 0) < (rhs.duration ?? 0)
        case .durationDescending:
            return (lhs.duration ?? 0) > (rhs.duration ?? 0)
        case .dateAddedNewest:
            return lhs.dateAdded > rhs.dateAdded
        case .dateAddedOldest:
            return lhs.dateAdded < rhs.dateAdded
        }
    }
}
