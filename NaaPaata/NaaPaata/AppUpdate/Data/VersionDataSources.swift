//
//  VersionDataSources.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import Foundation

enum AppUpdateConfiguration {

    /// Replace with your hosted JSON URL.
    /// Any publicly accessible HTTPS endpoint works — GitHub raw, a CDN,
    /// S3, JSONBin, or a static host.
    static let remoteVersionHistoryURL =
    URL(string: "https://raw.githubusercontent.com/mekala-vamsi-krishna/naa-paata-config/refs/heads/main/version_history.json"
    )!

    static let appStoreID = "6755621058"
    
    #if DEBUG
    static let forceShowUpdate = true
    static let fakeCurrentVersion = "1.0.0"
    #endif
}

// MARK: - Remote

final class VersionHistoryRemoteDataSource: VersionHistoryRemoteDataSourceProtocol {

    private let url: URL
    private let session: URLSession

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func fetch() async throws -> [VersionInfo] {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw AppUpdateError.invalidResponse
        }

        do {
            return try JSONDecoder().decode([VersionInfo].self, from: data)
        } catch {
            throw AppUpdateError.decodingFailed(error)
        }
    }
}

// MARK: - Local (Bundle)

final class VersionHistoryLocalDataSource: VersionHistoryLocalDataSourceProtocol {

    private let fileName: String
    private let bundle: Bundle

    init(fileName: String = "version_history", bundle: Bundle = .main) {
        self.fileName = fileName
        self.bundle = bundle
    }

    func load() throws -> [VersionInfo] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw AppUpdateError.bundledJSONMissing
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([VersionInfo].self, from: data)
    }
}

// MARK: - Disk Cache

final class VersionHistoryCache: VersionHistoryCacheProtocol {

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.naapaata.versionCache")

    init(fileName: String = "version_history_cache.json") {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent(fileName)
    }

    func save(_ versions: [VersionInfo]) throws {
        let data = try JSONEncoder().encode(versions)
        try queue.sync {
            try data.write(to: fileURL, options: .atomic)
        }
    }

    func load() throws -> [VersionInfo] {
        try queue.sync {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([VersionInfo].self, from: data)
        }
    }
}
