//
//  SongSortOption.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
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

    var systemImage: String {
        switch self {
        case .titleAscending, .titleDescending:   return "textformat.abc"
        case .artistAscending:                    return "music.mic"
        case .albumAscending:                     return "square.stack"
        case .durationAscending, .durationDescending: return "clock"
        case .dateAddedNewest, .dateAddedOldest:      return "calendar"
        }
    }

    /// Comparator used to sort a `[Song]` array.
    func areInIncreasingOrder(_ lhs: Song, _ rhs: Song) -> Bool {
        switch self {
        case .titleAscending:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        case .titleDescending:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedDescending
        case .artistAscending:
            let cmp = lhs.artist.localizedStandardCompare(rhs.artist)
            return cmp == .orderedAscending
                || (cmp == .orderedSame
                    && lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending)
        case .albumAscending:
            let cmp = lhs.album.localizedStandardCompare(rhs.album)
            return cmp == .orderedAscending
                || (cmp == .orderedSame
                    && lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending)
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
