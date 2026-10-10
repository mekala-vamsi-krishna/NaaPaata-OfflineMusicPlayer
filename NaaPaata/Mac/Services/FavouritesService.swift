//
//  FavouritesService.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/17/26.
//

import Foundation
import SwiftData

/// All favourite-song write operations. Reads are handled by `@Query` in views.
struct FavouritesService {

    let context: ModelContext

    func isFavourite(_ url: URL) throws -> Bool {
        let path = url.path
        let descriptor = FetchDescriptor<FavouriteSong>(
            predicate: #Predicate { $0.songPath == path }
        )
        return try context.fetchCount(descriptor) > 0
    }

    /// Adds or removes the favourite record for `url`.
    func toggleFavourite(_ url: URL) throws {
        let path = url.path
        let descriptor = FetchDescriptor<FavouriteSong>(
            predicate: #Predicate { $0.songPath == path }
        )
        let existing = try context.fetch(descriptor)

        if let record = existing.first {
            context.delete(record)
        } else {
            context.insert(FavouriteSong(songPath: path))
        }
        try context.save()
    }
    
    func removeFavourite(_ url: URL) throws {
        let path = url.path
        let descriptor = FetchDescriptor<FavouriteSong>(
            predicate: #Predicate { $0.songPath == path }
        )
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
        try context.save()
    }
}
