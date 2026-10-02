//
//  DocumentFolderService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation
import Combine

final class DocumentFolderService: ObservableObject {

    /// The app's Documents directory — visible in Files → On My iPhone → NaaPaata.
    var naaPaataFolderURL: URL? {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
    }

    /// Converts an absolute file URL into a path relative to Documents.
    /// Returns `nil` if the URL is not inside Documents.
    func relativePath(for url: URL) -> String? {
        guard let docs = naaPaataFolderURL else { return nil }
        let prefix = docs.path.hasSuffix("/") ? docs.path : docs.path + "/"
        guard url.path.hasPrefix(prefix) else { return nil }
        return String(url.path.dropFirst(prefix.count))
    }

    /// Rebuilds an absolute file URL from a relative path.
    func absoluteURL(for relativePath: String) -> URL? {
        guard let docs = naaPaataFolderURL else { return nil }
        return docs.appendingPathComponent(relativePath)
    }
}
