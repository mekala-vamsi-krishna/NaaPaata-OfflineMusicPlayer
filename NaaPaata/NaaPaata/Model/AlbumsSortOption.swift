//
//  AlbumsSortOption.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation

enum AlbumSortOption: String, CaseIterable, Identifiable {
    case titleAscending
    case titleDescending
    case artistAscending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAscending:  return "Title (A–Z)"
        case .titleDescending: return "Title (Z–A)"
        case .artistAscending: return "Artist (A–Z)"
        }
    }

    func areInIncreasingOrder(_ lhs: Album, _ rhs: Album) -> Bool {
        switch self {
        case .titleAscending:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        case .titleDescending:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedDescending
        case .artistAscending:
            return lhs.artist.localizedStandardCompare(rhs.artist) == .orderedAscending
        }
    }
}
