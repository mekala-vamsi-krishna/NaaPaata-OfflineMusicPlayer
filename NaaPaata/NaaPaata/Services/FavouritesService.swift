//
//  FavouritesService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//

import Foundation
import SwiftData

@MainActor
struct FavouritesService {

    let context: ModelContext

    // MARK: - Queries

    /// True if the song (identified by its relative path) is favourited.
    func isFavourite(_ relativePath: String) -> Bool {
        let descriptor = FetchDescriptor<FavouriteSong>(
            predicate: #Predicate { $0.songRelativePath == relativePath }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    /// All favourited songs, most recent first.
    func allFavourites() throws -> [FavouriteSong] {
        let descriptor = FetchDescriptor<FavouriteSong>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Mutations

    /// Adds the song as a favourite. No-op if already present.
    @discardableResult
    func addFavourite(_ relativePath: String) throws -> FavouriteChange {
        guard !isFavourite(relativePath) else { return .noChange }

        let favourite = FavouriteSong(songRelativePath: relativePath)
        context.insert(favourite)
        try context.save()
        return .applied
    }

    /// Removes the song from favourites. No-op if not present.
    @discardableResult
    func removeFavourite(_ relativePath: String) throws -> FavouriteChange {
        let descriptor = FetchDescriptor<FavouriteSong>(
            predicate: #Predicate { $0.songRelativePath == relativePath }
        )
        let matches = try context.fetch(descriptor)
        guard !matches.isEmpty else { return .noChange }

        for match in matches {
            context.delete(match)
        }
        try context.save()
        return .applied
    }

    /// Toggles the favourite state. Returns the new state.
    @discardableResult
    func toggleFavourite(_ relativePath: String) throws -> Bool {
        if isFavourite(relativePath) {
            try removeFavourite(relativePath)
            return false
        } else {
            try addFavourite(relativePath)
            return true
        }
    }
}

enum FavouriteChange: Equatable {
    case applied
    case noChange
}
