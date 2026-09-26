//
//  AlbumSortOption.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/12/26.
//

import Foundation

enum AlbumSortOption: String, CaseIterable, Identifiable {
    case titleAscending
    case titleDescending
    case artistAscending
    case trackCountDescending
    case durationDescending
    case dateAddedNewest
    case dateAddedOldest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAscending:        return "Title (A–Z)"
        case .titleDescending:       return "Title (Z–A)"
        case .artistAscending:       return "Artist (A–Z)"
        case .trackCountDescending:  return "Track Count (Most)"
        case .durationDescending:    return "Duration (Longest)"
        case .dateAddedNewest:       return "Date Added (Newest)"
        case .dateAddedOldest:       return "Date Added (Oldest)"
        }
    }

    var systemImage: String {
        switch self {
        case .titleAscending, .titleDescending:   return "textformat.abc"
        case .artistAscending:                    return "music.mic"
        case .trackCountDescending:               return "number"
        case .durationDescending:                 return "clock"
        case .dateAddedNewest, .dateAddedOldest:  return "calendar"
        }
    }

    func areInIncreasingOrder(_ lhs: Album, _ rhs: Album) -> Bool {
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
        case .trackCountDescending:
            return lhs.trackCount > rhs.trackCount
        case .durationDescending:
            return lhs.totalDuration > rhs.totalDuration
        case .dateAddedNewest:
            return lhs.mostRecentDateAdded > rhs.mostRecentDateAdded
        case .dateAddedOldest:
            return lhs.mostRecentDateAdded < rhs.mostRecentDateAdded
        }
    }
}
