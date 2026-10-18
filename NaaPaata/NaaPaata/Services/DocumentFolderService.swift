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

    func relativePath(for url: URL) -> String? {
        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let standardizedUrlPath = url.standardizedFileURL.path
        let standardizedDocsPath = docsURL.standardizedFileURL.path
        
        guard standardizedUrlPath.hasPrefix(standardizedDocsPath) else { return nil }
        
        var relative = standardizedUrlPath.replacingOccurrences(of: standardizedDocsPath, with: "")
        if relative.hasPrefix("/") { relative.removeFirst() }
        return relative
    }

    func absoluteURL(for relativePath: String) -> URL? {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docsURL.appendingPathComponent(relativePath).standardizedFileURL
    }
}
